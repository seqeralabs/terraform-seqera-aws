#
# Copyright 2023, Seqera Labs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

provider "helm" {
  debug = true
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# This module provisions a VPC (Virtual Private Cloud) in AWS using the terraform-aws-modules' VPC module.
# VPCs provide isolation for AWS resources and allow one to define a network with their own IP address range,
# subnets, internet gateways, route tables, and network gateways.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws" # The source from where the module is fetched.
  version = "5.1.2"                         # Specifies the version of the module to use.

  # Define the VPC name and CIDR block.
  name = var.vpc_name
  cidr = var.vpc_cidr

  # Enabling or disabling the DNS hostnames and DNS support in the VPC.
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Define the Availability Zones for the VPC and the CIDR blocks for various subnets.
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # Conditionally create database and elasticache subnets based on variables.
  database_subnets    = var.create_db_cluster ? var.database_subnets : []
  elasticache_subnets = var.create_redis_cluster ? var.elasticache_subnets : []

  intra_subnets = var.intra_subnets

  # Tags for the private and public subnets, commonly used for identifying subnets for Kubernetes clusters.
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/CLUSTER_NAME"        = var.cluster_name
    "kubernetes.io/role/internal-elb"           = "1"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/CLUSTER_NAME"        = var.cluster_name
    "kubernetes.io/role/elb"                    = "1"
  }

  # Settings to control the creation of specific subnet groups.
  create_database_subnet_group       = var.create_db_cluster
  create_elasticache_subnet_group    = var.create_redis_cluster
  create_database_subnet_route_table = var.create_db_cluster

  # Whether to create one NAT (Network Address Translation) gateway per availability zone.
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # Controls enabling NAT and VPN gateways.
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  # Default tags for VPC resources.
  tags = var.default_tags
}

# Using the 'locals' block to define local values or transformations. 
# Here, it defines two lists to set roles and users for the AWS EKS (Elastic Kubernetes Service) cluster.
locals {
  eks_aws_auth_roles = distinct(flatten(
    [
      for role in var.eks_aws_auth_roles : [
        {
          rolearn  = role
          username = element(split("/", role), 1) # Extracting the username from the role's ARN.
          groups   = ["system:masters"]
        }
      ]
    ]
  ))

  eks_aws_auth_users = distinct(flatten(
    [
      for user in var.eks_aws_auth_users : [
        {
          userarn  = user
          username = element(split("/", user), 1) # Extracting the username from the user's ARN.
          groups   = ["system:masters"]
        }
      ]
    ]
  ))
}

# This module provisions an AWS EKS cluster using the terraform-aws-modules' EKS module.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.19.0" # Specifies the version of the EKS module to use.

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = var.eks_cluster_endpoint_public_access

  cluster_addons = var.eks_cluster_addons

  enable_irsa = var.eks_enable_irsa

  # Specifying the VPC and subnets where the EKS cluster will reside.
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group settings.
  eks_managed_node_group_defaults = {
    instance_types               = var.eks_managed_node_group_defaults_instance_types
    iam_role_additional_policies = local.additional_policies
    subnet_ids                   = module.vpc.private_subnets
  }

  # Definition for specific node groups in the EKS cluster.
  eks_managed_node_groups = {
    seqera = {
      min_size     = var.seqera_managed_node_group_min_size
      max_size     = var.seqera_managed_node_group_max_size
      desired_size = var.seqera_managed_node_group_desired_size

      instance_types               = var.seqera_managed_node_group_defaults_instance_types
      iam_role_additional_policies = local.additional_policies
      capacity_type                = var.seqera_managed_node_group_defaults_capacity_type
      subnet_ids                   = module.vpc.private_subnets

      labels = merge(
        { "service" = "seqera" },
        var.default_tags,
        var.seqera_managed_node_group_labels
      )
    }
  }

  iam_role_additional_policies = local.additional_policies

  # AWS auth configuration for EKS to specify roles and users.
  manage_aws_auth_configmap = var.eks_manage_aws_auth_configmap
  aws_auth_roles            = local.eks_aws_auth_roles
  aws_auth_users            = local.eks_aws_auth_users

  tags = var.default_tags
}

# A resource to create a Kubernetes namespace.
resource "kubernetes_namespace_v1" "this" {
  count = var.create_seqera_namespace ? 1 : 0 || var.create_seqera_service_account ? 1 : 0

  metadata {
    name = var.seqera_namespace_name
  }
}

# A resource to create a Kubernetes service account within the specified namespace.
resource "kubernetes_service_account_v1" "this" {
  count = var.create_seqera_service_account ? 1 : 0

  metadata {
    name      = var.seqera_service_account_name
    namespace = var.seqera_namespace_name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.seqera_irsa[0].iam_role_arn
    }
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace_v1.this] # Ensures the namespace is created before the service account.
}

# DB Secret
resource "kubernetes_secret_v1" "db_app_password" {
  count = var.create_db_cluster && var.create_db_password_secret ? 1 : 0
  metadata {
    name      = var.db_password_secret_name
    namespace = var.seqera_namespace_name
  }

  data = {
    TOWER_DB_PASSWORD      = var.db_app_password != "" ? var.db_app_password : random_password.db_app_password[0].result
    TOWER_DB_ROOT_PASSWORD = var.db_root_password != "" ? var.db_root_password : random_password.db_root_password[0].result
  }

  type = "Opaque"

  depends_on = [
    module.eks
  ]
}

# Config Map
resource "kubernetes_config_map_v1" "tower_app_configmap" {
  count = var.create_db_cluster && var.create_redis_cluster && var.create_tower_app_configmap ? 1 : 0
  metadata {
    name      = var.tower_app_configmap_name
    namespace = var.seqera_namespace_name
  }

  data = {
    TOWER_DB_URL    = "jdbc:mysql://${module.db[0].db_instance_address}:3306/${var.db_app_schema_name}?&usePipelineAuth=false&useBatchMultiSend=false"
    TOWER_REDIS_URL = "redis://${module.redis[0].endpoint}:6379"
  }

  depends_on = [
    module.db,
    module.redis,
    module.eks
  ]
}

## This local is used to control the password values passed to the db setup job.
locals {
  db_root_password = var.db_root_password != "" ? var.db_root_password : random_password.db_root_password[0].result
  db_app_password  = var.db_app_password != "" ? var.db_app_password : random_password.db_app_password[0].result
}

# This resource creates a kubernetes that will provision the Seqera user in the DB with the required permissions.
resource "kubernetes_job_v1" "seqera_schema_job" {
  count = var.create_db_cluster ? 1 : 0
  metadata {
    name      = var.db_setup_job_name
    namespace = var.seqera_namespace_name
  }

  spec {
    backoff_limit = 1
    template {
      metadata {
        name = var.db_setup_job_name
      }

      spec {
        container {
          name    = var.db_setup_job_name
          image   = var.db_setup_job_image
          command = ["mysql"]
          args = [
            "--host=${module.db[0].db_instance_address}",
            "--user=${var.db_root_username}",
            "--password=${local.db_root_password}",
            "-e", <<-EOT
              ALTER DATABASE ${var.db_app_schema_name} CHARACTER SET utf8 COLLATE utf8_bin;
              CREATE USER IF NOT EXISTS ${var.db_app_username} IDENTIFIED BY "${local.db_app_password}";
              GRANT ALL PRIVILEGES ON ${var.db_app_username}.* TO ${var.db_app_username}@'%';
            EOT
          ]
        }

        restart_policy = "Never"

        dns_config {
          searches = ["kube-dns.kube-system.svc.cluster.local"]
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "10m"
    update = "5m"
  }

  depends_on = [
    module.eks,
    module.db
  ]
}

# A Helm release resource for deploying the AWS cluster autoscaler using the Helm package manager.
resource "helm_release" "aws_cluster_autoscaler" {
  count = var.enable_aws_cluster_autoscaler ? 1 : 0

  name       = "aws-cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.aws_cluster_autoscaler_version
  replace    = true
  atomic     = true
  wait       = true

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  depends_on = [
    module.eks
  ]
}

# A Helm release resource for deploying the AWS EBS CSI driver using the Helm package manager.
resource "helm_release" "aws-ebs-csi-driver" {
  count = var.enable_aws_ebs_csi_driver ? 1 : 0

  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = var.aws_ebs_csi_driver_version
  replace    = true
  atomic     = true
  wait       = true

  depends_on = [
    module.eks,
    module.aws_ebs_csi_driver_iam_policy
  ]
}

# Customer Resource Definition (CRD) for the AWS Load Balancer Controller.
resource "kubectl_manifest" "aws_loadbalancer_controller_crd" {
  count     = var.enable_aws_loadbalancer_controller ? 1 : 0
  yaml_body = <<YAML
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.11.1
  creationTimestamp: null
  name: ingressclassparams.elbv2.k8s.aws
spec:
  group: elbv2.k8s.aws
  names:
    kind: IngressClassParams
    listKind: IngressClassParamsList
    plural: ingressclassparams
    singular: ingressclassparams
  scope: Cluster
  versions:
  - additionalPrinterColumns:
    - description: The Ingress Group name
      jsonPath: .spec.group.name
      name: GROUP-NAME
      type: string
    - description: The AWS Load Balancer scheme
      jsonPath: .spec.scheme
      name: SCHEME
      type: string
    - description: The AWS Load Balancer ipAddressType
      jsonPath: .spec.ipAddressType
      name: IP-ADDRESS-TYPE
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: AGE
      type: date
    name: v1beta1
    schema:
      openAPIV3Schema:
        description: IngressClassParams is the Schema for the IngressClassParams API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: IngressClassParamsSpec defines the desired state of IngressClassParams
            properties:
              group:
                description: Group defines the IngressGroup for all Ingresses that
                  belong to IngressClass with this IngressClassParams.
                properties:
                  name:
                    description: Name is the name of IngressGroup.
                    type: string
                required:
                - name
                type: object
              inboundCIDRs:
                description: InboundCIDRs specifies the CIDRs that are allowed to
                  access the Ingresses that belong to IngressClass with this IngressClassParams.
                items:
                  type: string
                type: array
              ipAddressType:
                description: IPAddressType defines the ip address type for all Ingresses
                  that belong to IngressClass with this IngressClassParams.
                enum:
                - ipv4
                - dualstack
                type: string
              loadBalancerAttributes:
                description: LoadBalancerAttributes define the custom attributes to
                  LoadBalancers for all Ingress that that belong to IngressClass with
                  this IngressClassParams.
                items:
                  description: Attributes defines custom attributes on resources.
                  properties:
                    key:
                      description: The key of the attribute.
                      type: string
                    value:
                      description: The value of the attribute.
                      type: string
                  required:
                  - key
                  - value
                  type: object
                type: array
              namespaceSelector:
                description: NamespaceSelector restrict the namespaces of Ingresses
                  that are allowed to specify the IngressClass with this IngressClassParams.
                  * if absent or present but empty, it selects all namespaces.
                properties:
                  matchExpressions:
                    description: matchExpressions is a list of label selector requirements.
                      The requirements are ANDed.
                    items:
                      description: A label selector requirement is a selector that
                        contains values, a key, and an operator that relates the key
                        and values.
                      properties:
                        key:
                          description: key is the label key that the selector applies
                            to.
                          type: string
                        operator:
                          description: operator represents a key's relationship to
                            a set of values. Valid operators are In, NotIn, Exists
                            and DoesNotExist.
                          type: string
                        values:
                          description: values is an array of string values. If the
                            operator is In or NotIn, the values array must be non-empty.
                            If the operator is Exists or DoesNotExist, the values
                            array must be empty. This array is replaced during a strategic
                            merge patch.
                          items:
                            type: string
                          type: array
                      required:
                      - key
                      - operator
                      type: object
                    type: array
                  matchLabels:
                    additionalProperties:
                      type: string
                    description: matchLabels is a map of {key,value} pairs. A single
                      {key,value} in the matchLabels map is equivalent to an element
                      of matchExpressions, whose key field is "key", the operator
                      is "In", and the values array contains only "value". The requirements
                      are ANDed.
                    type: object
                type: object
                x-kubernetes-map-type: atomic
              scheme:
                description: Scheme defines the scheme for all Ingresses that belong
                  to IngressClass with this IngressClassParams.
                enum:
                - internal
                - internet-facing
                type: string
              sslPolicy:
                description: SSLPolicy specifies the SSL Policy for all Ingresses
                  that belong to IngressClass with this IngressClassParams.
                type: string
              subnets:
                description: Subnets defines the subnets for all Ingresses that belong
                  to IngressClass with this IngressClassParams.
                properties:
                  ids:
                    description: IDs specify the resource IDs of subnets. Exactly
                      one of this or `tags` must be specified.
                    items:
                      description: SubnetID specifies a subnet ID.
                      pattern: subnet-[0-9a-f]+
                      type: string
                    minItems: 1
                    type: array
                  tags:
                    additionalProperties:
                      items:
                        type: string
                      type: array
                    description: Tags specifies subnets in the load balancer's VPC
                      where each tag specified in the map key contains one of the
                      values in the corresponding value list. Exactly one of this
                      or `ids` must be specified.
                    type: object
                type: object
              tags:
                description: Tags defines list of Tags on AWS resources provisioned
                  for Ingresses that belong to IngressClass with this IngressClassParams.
                items:
                  description: Tag defines a AWS Tag on resources.
                  properties:
                    key:
                      description: The key of the tag.
                      type: string
                    value:
                      description: The value of the tag.
                      type: string
                  required:
                  - key
                  - value
                  type: object
                type: array
            type: object
        type: object
    served: true
    storage: true
    subresources: {}
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.11.1
  creationTimestamp: null
  name: targetgroupbindings.elbv2.k8s.aws
spec:
  group: elbv2.k8s.aws
  names:
    kind: TargetGroupBinding
    listKind: TargetGroupBindingList
    plural: targetgroupbindings
    singular: targetgroupbinding
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: The Kubernetes Service's name
      jsonPath: .spec.serviceRef.name
      name: SERVICE-NAME
      type: string
    - description: The Kubernetes Service's port
      jsonPath: .spec.serviceRef.port
      name: SERVICE-PORT
      type: string
    - description: The AWS TargetGroup's TargetType
      jsonPath: .spec.targetType
      name: TARGET-TYPE
      type: string
    - description: The AWS TargetGroup's Amazon Resource Name
      jsonPath: .spec.targetGroupARN
      name: ARN
      priority: 1
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: AGE
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: TargetGroupBinding is the Schema for the TargetGroupBinding API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: TargetGroupBindingSpec defines the desired state of TargetGroupBinding
            properties:
              networking:
                description: networking provides the networking setup for ELBV2 LoadBalancer
                  to access targets in TargetGroup.
                properties:
                  ingress:
                    description: List of ingress rules to allow ELBV2 LoadBalancer
                      to access targets in TargetGroup.
                    items:
                      properties:
                        from:
                          description: List of peers which should be able to access
                            the targets in TargetGroup. At least one NetworkingPeer
                            should be specified.
                          items:
                            description: NetworkingPeer defines the source/destination
                              peer for networking rules.
                            properties:
                              ipBlock:
                                description: IPBlock defines an IPBlock peer. If specified,
                                  none of the other fields can be set.
                                properties:
                                  cidr:
                                    description: CIDR is the network CIDR. Both IPV4
                                      or IPV6 CIDR are accepted.
                                    type: string
                                required:
                                - cidr
                                type: object
                              securityGroup:
                                description: SecurityGroup defines a SecurityGroup
                                  peer. If specified, none of the other fields can
                                  be set.
                                properties:
                                  groupID:
                                    description: GroupID is the EC2 SecurityGroupID.
                                    type: string
                                required:
                                - groupID
                                type: object
                            type: object
                          type: array
                        ports:
                          description: List of ports which should be made accessible
                            on the targets in TargetGroup. If ports is empty or unspecified,
                            it defaults to all ports with TCP.
                          items:
                            properties:
                              port:
                                anyOf:
                                - type: integer
                                - type: string
                                description: The port which traffic must match. When
                                  NodePort endpoints(instance TargetType) is used,
                                  this must be a numerical port. When Port endpoints(ip
                                  TargetType) is used, this can be either numerical
                                  or named port on pods. if port is unspecified, it
                                  defaults to all ports.
                                x-kubernetes-int-or-string: true
                              protocol:
                                description: The protocol which traffic must match.
                                  If protocol is unspecified, it defaults to TCP.
                                enum:
                                - TCP
                                - UDP
                                type: string
                            type: object
                          type: array
                      required:
                      - from
                      - ports
                      type: object
                    type: array
                type: object
              serviceRef:
                description: serviceRef is a reference to a Kubernetes Service and
                  ServicePort.
                properties:
                  name:
                    description: Name is the name of the Service.
                    type: string
                  port:
                    anyOf:
                    - type: integer
                    - type: string
                    description: Port is the port of the ServicePort.
                    x-kubernetes-int-or-string: true
                required:
                - name
                - port
                type: object
              targetGroupARN:
                description: targetGroupARN is the Amazon Resource Name (ARN) for
                  the TargetGroup.
                type: string
              targetType:
                description: targetType is the TargetType of TargetGroup. If unspecified,
                  it will be automatically inferred.
                enum:
                - instance
                - ip
                type: string
            required:
            - serviceRef
            - targetGroupARN
            type: object
          status:
            description: TargetGroupBindingStatus defines the observed state of TargetGroupBinding
            properties:
              observedGeneration:
                description: The generation observed by the TargetGroupBinding controller.
                format: int64
                type: integer
            type: object
        type: object
    served: true
    storage: false
    subresources:
      status: {}
  - additionalPrinterColumns:
    - description: The Kubernetes Service's name
      jsonPath: .spec.serviceRef.name
      name: SERVICE-NAME
      type: string
    - description: The Kubernetes Service's port
      jsonPath: .spec.serviceRef.port
      name: SERVICE-PORT
      type: string
    - description: The AWS TargetGroup's TargetType
      jsonPath: .spec.targetType
      name: TARGET-TYPE
      type: string
    - description: The AWS TargetGroup's Amazon Resource Name
      jsonPath: .spec.targetGroupARN
      name: ARN
      priority: 1
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: AGE
      type: date
    name: v1beta1
    schema:
      openAPIV3Schema:
        description: TargetGroupBinding is the Schema for the TargetGroupBinding API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: TargetGroupBindingSpec defines the desired state of TargetGroupBinding
            properties:
              ipAddressType:
                description: ipAddressType specifies whether the target group is of
                  type IPv4 or IPv6. If unspecified, it will be automatically inferred.
                enum:
                - ipv4
                - ipv6
                type: string
              networking:
                description: networking defines the networking rules to allow ELBV2
                  LoadBalancer to access targets in TargetGroup.
                properties:
                  ingress:
                    description: List of ingress rules to allow ELBV2 LoadBalancer
                      to access targets in TargetGroup.
                    items:
                      description: NetworkingIngressRule defines a particular set
                        of traffic that is allowed to access TargetGroup's targets.
                      properties:
                        from:
                          description: List of peers which should be able to access
                            the targets in TargetGroup. At least one NetworkingPeer
                            should be specified.
                          items:
                            description: NetworkingPeer defines the source/destination
                              peer for networking rules.
                            properties:
                              ipBlock:
                                description: IPBlock defines an IPBlock peer. If specified,
                                  none of the other fields can be set.
                                properties:
                                  cidr:
                                    description: CIDR is the network CIDR. Both IPV4
                                      or IPV6 CIDR are accepted.
                                    type: string
                                required:
                                - cidr
                                type: object
                              securityGroup:
                                description: SecurityGroup defines a SecurityGroup
                                  peer. If specified, none of the other fields can
                                  be set.
                                properties:
                                  groupID:
                                    description: GroupID is the EC2 SecurityGroupID.
                                    type: string
                                required:
                                - groupID
                                type: object
                            type: object
                          type: array
                        ports:
                          description: List of ports which should be made accessible
                            on the targets in TargetGroup. If ports is empty or unspecified,
                            it defaults to all ports with TCP.
                          items:
                            description: NetworkingPort defines the port and protocol
                              for networking rules.
                            properties:
                              port:
                                anyOf:
                                - type: integer
                                - type: string
                                description: The port which traffic must match. When
                                  NodePort endpoints(instance TargetType) is used,
                                  this must be a numerical port. When Port endpoints(ip
                                  TargetType) is used, this can be either numerical
                                  or named port on pods. if port is unspecified, it
                                  defaults to all ports.
                                x-kubernetes-int-or-string: true
                              protocol:
                                description: The protocol which traffic must match.
                                  If protocol is unspecified, it defaults to TCP.
                                enum:
                                - TCP
                                - UDP
                                type: string
                            type: object
                          type: array
                      required:
                      - from
                      - ports
                      type: object
                    type: array
                type: object
              nodeSelector:
                description: node selector for instance type target groups to only
                  register certain nodes
                properties:
                  matchExpressions:
                    description: matchExpressions is a list of label selector requirements.
                      The requirements are ANDed.
                    items:
                      description: A label selector requirement is a selector that
                        contains values, a key, and an operator that relates the key
                        and values.
                      properties:
                        key:
                          description: key is the label key that the selector applies
                            to.
                          type: string
                        operator:
                          description: operator represents a key's relationship to
                            a set of values. Valid operators are In, NotIn, Exists
                            and DoesNotExist.
                          type: string
                        values:
                          description: values is an array of string values. If the
                            operator is In or NotIn, the values array must be non-empty.
                            If the operator is Exists or DoesNotExist, the values
                            array must be empty. This array is replaced during a strategic
                            merge patch.
                          items:
                            type: string
                          type: array
                      required:
                      - key
                      - operator
                      type: object
                    type: array
                  matchLabels:
                    additionalProperties:
                      type: string
                    description: matchLabels is a map of {key,value} pairs. A single
                      {key,value} in the matchLabels map is equivalent to an element
                      of matchExpressions, whose key field is "key", the operator
                      is "In", and the values array contains only "value". The requirements
                      are ANDed.
                    type: object
                type: object
                x-kubernetes-map-type: atomic
              serviceRef:
                description: serviceRef is a reference to a Kubernetes Service and
                  ServicePort.
                properties:
                  name:
                    description: Name is the name of the Service.
                    type: string
                  port:
                    anyOf:
                    - type: integer
                    - type: string
                    description: Port is the port of the ServicePort.
                    x-kubernetes-int-or-string: true
                required:
                - name
                - port
                type: object
              targetGroupARN:
                description: targetGroupARN is the Amazon Resource Name (ARN) for
                  the TargetGroup.
                minLength: 1
                type: string
              targetType:
                description: targetType is the TargetType of TargetGroup. If unspecified,
                  it will be automatically inferred.
                enum:
                - instance
                - ip
                type: string
            required:
            - serviceRef
            - targetGroupARN
            type: object
          status:
            description: TargetGroupBindingStatus defines the observed state of TargetGroupBinding
            properties:
              observedGeneration:
                description: The generation observed by the TargetGroupBinding controller.
                format: int64
                type: integer
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
YAML

  depends_on = [
    module.eks
  ]
}

# A Helm release resource for deploying the AWS Load Balancer Controller using the Helm package manager.
resource "helm_release" "aws-load-balancer-controller" {
  count = var.enable_aws_loadbalancer_controller ? 1 : 0

  name            = "aws-load-balancer-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  namespace       = "kube-system"
  version         = var.aws_loadbalancer_controller_version
  atomic          = true
  cleanup_on_fail = true
  replace         = true

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks,
    kubectl_manifest.aws_loadbalancer_controller_crd
  ]
}
# This resource creates an AWS Elastic File System (EFS) specifically for the EKS cluster.
resource "aws_efs_file_system" "eks_efs" {
  count            = var.enable_aws_efs_csi_driver ? 1 : 0      # Only creates the EFS if the `enable_aws_efs_csi_driver` variable is true.
  creation_token   = var.aws_efs_csi_driver_creation_token_name # Token used to ensure idempotent creation (preventing duplicate filesystems).
  performance_mode = var.aws_efs_csi_driver_performance_mode    # Defines the performance mode for the EFS (generalPurpose or maxIO).

  tags = {
    Name = var.cluster_name # Tags the EFS with the cluster name.
  }
}

# This resource creates a backup policy for the EFS.
resource "aws_efs_backup_policy" "eks_efs" {
  count          = var.enable_aws_efs_csi_driver ? 1 : 0 # Only creates the backup policy if the `enable_aws_efs_csi_driver` variable is true.
  file_system_id = aws_efs_file_system.eks_efs[0].id     # References the ID of the EFS created above.

  backup_policy {
    status = var.aws_efs_csi_driver_backup_policy_status # Status of the backup policy (usually either "ENABLED" or "DISABLED").
  }
}

# This resource creates mount targets for the EFS within the private subnets of the VPC.
resource "aws_efs_mount_target" "eks_efs_mount_target" {
  count           = var.enable_aws_efs_csi_driver ? length(module.vpc.private_subnets) : 0 # Creates a mount target for each private subnet if `enable_aws_efs_csi_driver` is true.
  file_system_id  = aws_efs_file_system.eks_efs[0].id                                      # References the ID of the EFS created above.
  subnet_id       = element(module.vpc.private_subnets, count.index)                       # Specifies which private subnet the mount target will be in.
  security_groups = [module.efs_sg[0].security_group_id]                                   # Security group associated with the EFS mount target.

  depends_on = [
    module.vpc,
    module.efs_sg
  ]
}

# This resource creates an access point for the EFS. Access points are application-specific entry points into the EFS.
resource "aws_efs_access_point" "eks_efs_access_point" {
  count          = var.enable_aws_efs_csi_driver ? 1 : 0 # Only creates the access point if the `enable_aws_efs_csi_driver` variable is true.
  file_system_id = aws_efs_file_system.eks_efs[0].id     # References the ID of the EFS created above.
}

# This resource creates a Kubernetes storage class specifically for the EFS. Storage classes define how storage is provisioned and its parameters.
resource "kubernetes_storage_class" "efs_storage_class" {
  count = var.enable_aws_efs_csi_driver ? 1 : 0 # Only creates the storage class if the `enable_aws_efs_csi_driver` variable is true.

  metadata {
    name = var.aws_efs_csi_driver_storage_class_name # Name of the storage class.
  }

  storage_provisioner = var.aws_efs_csi_driver_storage_class_storage_provisioner_name # The provisioner responsible for creating the storage.
  reclaim_policy      = var.aws_efs_csi_driver_storage_class_reclaim_policy           # Specifies what happens to the storage upon deletion (e.g., "Retain" or "Delete").

  parameters = { # Parameters associated with the storage class.
    provisioningMode = var.aws_efs_csi_driver_storage_class_parameters["provisioningMode"]
    fileSystemId     = aws_efs_file_system.eks_efs[0].id
    directoryPerms   = var.aws_efs_csi_driver_storage_class_parameters["directoryPerms"]
    gidRangeStart    = var.aws_efs_csi_driver_storage_class_parameters["gidRangeStart"]
    gidRangeEnd      = var.aws_efs_csi_driver_storage_class_parameters["gidRangeEnd"]
    basePath         = var.aws_efs_csi_driver_storage_class_parameters["basePath"]
  }

  depends_on = [
    module.eks # Ensures that the EKS module is completely applied before this resource.
  ]
}

# This resource installs the AWS EFS CSI driver using Helm, a package manager for Kubernetes.
resource "helm_release" "aws-efs-csi-driver" {
  count           = var.enable_aws_efs_csi_driver ? 1 : 0                   # Only installs the Helm chart if the `enable_aws_efs_csi_driver` variable is true.
  name            = "aws-efs-csi-driver"                                    # Name of the Helm release.
  repository      = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/" # Helm chart repository URL.
  chart           = "aws-efs-csi-driver"                                    # The name of the chart to install.
  namespace       = "kube-system"                                           # Kubernetes namespace where the Helm chart will be installed.
  replace         = true                                                    # If true, replaces the existing Helm release with the same name.
  version         = var.aws_efs_csi_driver_version                          # Specifies the chart version to install.
  atomic          = true                                                    # If set to true, the installation process rolls back changes in case of a failed install.
  cleanup_on_fail = true                                                    # If set to true, removes resources and rollbacks in case of a failed installation.

  set {
    name  = "controller.serviceAccount.create" # Configuration parameter for the Helm chart.
    value = true                               # Sets the `controller.serviceAccount.create` parameter value to true.
  }
}

# This module creates a security group specifically for the database (DB) cluster.
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws" # Using a community Terraform AWS security group module.
  version = "5.1.0"                                    # Specifies the version of the module to use.
  count   = var.create_db_cluster ? 1 : 0              # Creates the security group only if the 'create_db_cluster' variable is set to true.

  name        = var.db_security_group_name                                       # The name of the security group, sourced from a variable.
  description = "Security group for access from seqera EKS cluster to seqera db" # Description of the purpose of this security group.
  vpc_id      = module.vpc.vpc_id                                                # The VPC ID where this security group will be created, sourced from the 'vpc' module.

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks # Allows incoming traffic from the private subnets of the VPC.
  ingress_rules       = [var.db_ingress_rule_name]             # Specific set of ingress rules (e.g., allowing TCP port 5432 for PostgreSQL).

  depends_on = [module.vpc]
}

# This module creates a security group specifically for the Redis cluster.
module "redis_sg" {
  source  = "terraform-aws-modules/security-group/aws" # Using a community Terraform AWS security group module.
  version = "5.1.0"                                    # Specifies the version of the module to use.
  count   = var.create_redis_cluster ? 1 : 0           # Creates the security group only if the 'create_redis_cluster' variable is set to true.

  name        = var.redis_security_group_name                                       # The name of the security group, sourced from a variable.
  description = "Security group for access from seqera EKS cluster to seqera redis" # Description of the purpose of this security group.
  vpc_id      = module.vpc.vpc_id                                                   # The VPC ID where this security group will be created, sourced from the 'vpc' module.

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks # Allows incoming traffic from the private subnets of the VPC.
  ingress_rules       = [var.redis_ingress_rule]               # Specific set of ingress rules (e.g., allowing TCP port 6379 for Redis).

  depends_on = [module.vpc]
}

# This module creates a security group specifically for the AWS EFS CSI Driver.
module "efs_sg" {
  count   = var.enable_aws_efs_csi_driver ? 1 : 0      # Creates the security group only if the 'enable_aws_efs_csi_driver' variable is set to true.
  version = "5.1.0"                                    # Specifies the version of the module to use.
  source  = "terraform-aws-modules/security-group/aws" # Using a community Terraform AWS security group module.

  name        = var.aws_efs_csi_driver_security_group_name                          # The name of the security group, sourced from a variable.
  description = "Security group for access from seqera EKS cluster to seqera redis" # Description of the purpose of this security group. [Note: This description seems like a typo as it mentions "redis" but is actually for "EFS".]
  vpc_id      = module.vpc.vpc_id                                                   # The VPC ID where this security group will be created, sourced from the 'vpc' module.

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks                    # Allows incoming traffic from the private subnets of the VPC.
  ingress_rules       = [var.aws_efs_csi_driver_security_group_ingress_rule_name] # Specific set of ingress rules.
  egress_cidr_blocks  = module.vpc.private_subnets_cidr_blocks                    # Allows outgoing traffic to the private subnets of the VPC.

  depends_on = [module.vpc]
}

module "ec2_sg" {
  count   = var.create_ec2_instance || var.create_ec2_spot_instance ? 1 : 0 # Creates the security group only if the 'enable_aws_efs_csi_driver' variable is set to true.
  version = "5.1.0"                                                         # Specifies the version of the module to use.
  source  = "terraform-aws-modules/security-group/aws"                      # Using a community Terraform AWS security group module.

  name        = var.ec2_instance_security_group_name                 # The name of the security group, sourced from a variable.
  description = "Security group for access from seqera EC2 instance" # Description of the purpose of this security group. [Note: This description seems like a typo as it mentions "redis" but is actually for "EFS".]
  vpc_id      = module.vpc.vpc_id                                    # The VPC ID where this security group will be created, sourced from the 'vpc' module.

  ingress_cidr_blocks = var.ec2_instance_sg_ingress_cidr_blocks           # Allows incoming traffic from the private subnets of the VPC.
  ingress_rules       = var.ec2_instan_security_group_ingress_rules_names # Specific set of ingress rules.
  egress_cidr_blocks  = var.ec2_instance_sg_egress_cidr_blocks            # Allows outgoing traffic to the private subnets of the VPC.

  depends_on = [module.vpc]
}

# This resource generates a random password specifically for the database cluster.
resource "random_password" "db_app_password" {
  count = var.create_db_cluster ? 1 : 0 # Generates the password only if the 'create_db_cluster' variable is set to true.

  length  = 16    # The length of the password will be 16 characters.
  special = false # Indicates that special characters can be used in the password.
}

# This resource generates a random master password specifically for the database cluster.
resource "random_password" "db_root_password" {
  count = var.create_db_cluster ? 1 : 0 # Generates the password only if the 'create_db_cluster' variable is set to true.

  length           = 16                     # The length of the password will be 16 characters.
  special          = true                   # Indicates that special characters can be used in the password.
  override_special = "!#$%&*()-_=+[]{}<>:?" # Specifies which special characters can be used in the password.
}

# This module creates an RDS (Relational Database Service) instance or cluster in AWS.
module "db" {
  source  = "terraform-aws-modules/rds/aws" # Utilizes a community Terraform AWS RDS module.
  version = "6.1.1"                         # Specifies the version of the module to use.
  count   = var.create_db_cluster ? 1 : 0   # This determines whether to create the DB or not based on a variable.

  # Basic DB settings
  identifier                  = var.database_identifier            # Unique identifier for the DB instance.
  manage_master_user_password = var.db_manage_master_user_password # Whether Terraform manages the master user password.

  engine              = "mysql"                    # Specifies the type of database engine (in this case, MySQL).
  engine_version      = var.db_engine_version      # The version of the database engine.
  instance_class      = var.db_instance_class      # Instance type of the RDS instance.
  allocated_storage   = var.db_allocated_storage   # Allocated storage in gigabytes.
  skip_final_snapshot = var.db_skip_final_snapshot # Determines if a final DB snapshot is created before the DB instance is deleted.

  # Database access configuration
  db_name  = var.db_app_schema_name # The name of the database to be created.
  username = var.db_root_username   # Master username for the DB.
  port     = var.db_port            # The port on which the DB accepts connections.
  # If a DB password is provided in the variable, use that. Otherwise, use the randomly generated password.
  password = var.db_root_password != "" ? var.db_app_password : random_password.db_root_password[0].result

  iam_database_authentication_enabled = var.db_iam_database_authentication_enabled # Enable IAM authentication for the DB.

  # Linking the DB to the created security group
  vpc_security_group_ids = [module.db_sg[0].security_group_id]

  # Maintenance and backup settings
  maintenance_window = var.db_maintenance_window # Time window for DB maintenance.
  backup_window      = var.db_backup_window      # Preferred window for DB backups.

  # Enhanced Monitoring settings
  monitoring_interval    = var.db_monitoring_interval    # Monitoring interval in seconds.
  monitoring_role_name   = var.db_monitoring_role_name   # IAM role for RDS enhanced monitoring.
  create_monitoring_role = var.db_create_monitoring_role # Determines if the monitoring role should be created by Terraform.

  tags = var.default_tags # Apply default tags to the resource.

  # DB subnet group configuration
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # DB parameter group configuration
  family = var.db_family # Database parameter group family.

  # DB option group configuration
  major_engine_version = var.db_major_engine_version # Major version of the database engine.

  # Additional DB settings
  deletion_protection = var.db_deletion_protection # Protection against accidental DB deletion.

  # Advanced DB configurations
  parameters = var.db_parameters # Database parameters to apply.
  options    = var.db_options    # Database options to apply.

  depends_on = [
    module.vpc,
    module.db_sg
  ]
}

# Terraform Module to define a consistent naming convention by (namespace, stage, name, [attributes])
module "this" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  count   = var.create_redis_cluster ? 1 : 0

  namespace = "default"
  stage     = var.environment
  name      = var.cluster_name
}

# Terraform module to provision an ElastiCache Redis Cluster.
module "redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "0.52.0"
  count   = var.create_redis_cluster ? 1 : 0

  availability_zones            = var.azs
  vpc_id                        = module.vpc.vpc_id
  description                   = var.redis_cluster_description
  allowed_security_group_ids    = [module.eks.cluster_primary_security_group_id]
  auto_minor_version_upgrade    = var.redis_auto_minor_version_upgrade
  replication_group_id          = "${var.cluster_name}-redis"
  associated_security_group_ids = [module.redis_sg[0].security_group_id]
  elasticache_subnet_group_name = module.vpc.elasticache_subnet_group_name
  create_security_group         = false
  subnets                       = module.vpc.elasticache_subnets
  cluster_size                  = var.redis_cluster_size
  instance_type                 = var.redis_instance_type
  apply_immediately             = var.redis_apply_immediately
  automatic_failover_enabled    = var.redis_automatic_failover_enabled
  engine_version                = var.redis_engine_version
  family                        = var.redis_family
  at_rest_encryption_enabled    = var.redis_at_rest_encryption_enabled
  transit_encryption_enabled    = var.redis_transit_encryption_enabled
  maintenance_window            = var.redis_maintenance_window
  snapshot_retention_limit      = var.redis_snapshot_retention_limit
  snapshot_window               = var.redis_snapshot_window

  parameter                   = var.redis_parameters
  parameter_group_description = var.redis_parameter_group_description

  context = module.this[0].context

  tags = var.default_tags

  depends_on = [
    module.vpc,
    module.redis_sg,
    module.this
  ]
}

locals {
  # The following local variables are used to create unique IAM names (roles and policies).
  # The names are constructed by combining the input variable, the cluster name, region, 
  # and a random hexadecimal value (`random_id.this.hex`).

  seqera_irsa_role_name                       = "${var.seqera_irsa_role_name}-${var.cluster_name}-${var.region}"
  seqera_irsa_iam_policy_name                 = "${var.seqera_irsa_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_loadbalancer_controller_iam_policy_name = "${var.aws_loadbalancer_controller_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_cluster_autoscaler_iam_policy_name      = "${var.aws_cluster_autoscaler_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_efs_csi_driver_iam_policy_name          = "${var.aws_efs_csi_driver_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_ebs_csi_driver_iam_policy_name          = "${var.aws_ebs_csi_driver_iam_policy_name}-${var.cluster_name}-${var.region}"
  ec2_instance_profile_iam_policy_name        = "${var.ec2_instance_profile_iam_policy_name}-${var.ec2_instance_name}-${var.region}"


  # The next set of local variables are conditional policy mappings.
  # If the respective feature is enabled (e.g., `var.enable_aws_loadbalancer_controller` is true), 
  # the policy ARN from the associated module is stored in a map. 
  # Otherwise, an empty map is returned.

  aws_loadbalancer_controller_policy = var.enable_aws_loadbalancer_controller ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
  } : {}

  aws_ebs_csi_driver_policy = var.enable_aws_ebs_csi_driver ? {
    aws_ebs_csi_driver_iam_policy = module.aws_ebs_csi_driver_iam_policy[0].arn
  } : {}

  aws_cluster_autoscaler_policy = var.enable_aws_cluster_autoscaler ? {
    aws_cluster_autoscaler_iam_policy = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : {}

  aws_efs_csi_driver_policy = var.enable_aws_efs_csi_driver ? {
    aws_efs_csi_driver_iam_policy = module.aws_efs_csi_driver_iam_policy[0].arn
  } : {}

  # `additional_policies` combines all the above policy mappings into a single map using the `merge` function.
  # If multiple policies are enabled, their mappings are merged together.

  additional_policies = merge(
    local.aws_loadbalancer_controller_policy,
    local.aws_ebs_csi_driver_policy,
    local.aws_cluster_autoscaler_policy,
    local.aws_efs_csi_driver_policy
  )
}

# This module creates an IAM policy specifically for Seqera.
module "seqera_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"                                  # Specifies the version of the module to use.
  count   = var.create_seqera_service_account ? 1 : 0 # Conditional creation of the IAM policy based on the variable.

  name        = local.seqera_irsa_iam_policy_name
  path        = "/" # The path in which the policy is created.
  description = "This policy provides the permissions needed for seqera service account to interact with the required AWS services."

  policy = var.seqera_platform_service_account_iam_policy # Policy content or document.

  tags = var.default_tags # Assigning default tags.
}

# This module creates an IAM policy for the AWS Load Balancer Controller.
module "aws_loadbalancer_controller_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"                                       # Specifies the version of the module to use.
  count   = var.enable_aws_loadbalancer_controller ? 1 : 0 # Conditional creation based on the variable.

  name        = local.aws_loadbalancer_controller_iam_policy_name
  path        = "/"
  description = "This policy provides the permissions needed for AWS loadBalancer controller"

  policy = var.aws_loadbalancer_controller_iam_policy # Policy content or document.

  tags = var.default_tags # Assigning default tags.
}

# This module creates an IAM policy for the AWS EFS CSI Driver.
module "aws_efs_csi_driver_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"                              # Specifies the version of the module to use.
  count   = var.enable_aws_efs_csi_driver ? 1 : 0 # Conditional creation based on the variable.

  name        = local.aws_efs_csi_driver_iam_policy_name
  path        = "/"
  description = "This policy provides the permissions needed for AWS EFS CSI driver"

  policy = var.aws_efs_csi_driver_iam_policy # Policy content or document.

  tags = var.default_tags # Assigning default tags.
}

# This module creates an IAM policy for the AWS Cluster Autoscaler.
module "aws_cluster_autoscaler_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"                                  # Specifies the version of the module to use.
  count   = var.enable_aws_cluster_autoscaler ? 1 : 0 # Conditional creation based on the variable.

  name        = local.aws_cluster_autoscaler_iam_policy_name
  path        = "/"
  description = "This policy provides the permissions needed for AWS cluster autoscaler"

  policy = var.aws_cluster_autoscaler_iam_policy # Policy content or document.

  tags = var.default_tags # Assigning default tags.
}

# This module creates an IAM policy for the EBS CSI Driver.
module "aws_ebs_csi_driver_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"                              # Specifies the version of the module to use.
  count   = var.enable_aws_ebs_csi_driver ? 1 : 0 # Conditional creation based on the variable.

  name        = local.aws_ebs_csi_driver_iam_policy_name
  path        = "/"
  description = "This policy provides the permissions needed for EBS CSI driver"

  policy = var.aws_ebs_csi_driver_iam_policy # Policy content or document.

  tags = var.default_tags # Assigning default tags.
}

module "ec2_instance_profile_iam_policy" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version     = "5.30.0"                                                                                                                                                        # Specifies the version of the module to use.
  count       = var.create_ec2_instance && var.create_ec2_instance_iam_instance_profile || var.create_ec2_spot_instance && var.create_ec2_instance_iam_instance_profile ? 1 : 0 # Conditional creation based on the variable.
  name        = local.ec2_instance_profile_iam_policy_name
  path        = "/"
  description = "This is the policy associated with the EC2 Instance Role."

  policy = var.ec2_instance_profile_iam_policy # Policy content or document.

  tags = var.default_tags # Assigning default tags.
}

# This module creates an IAM role for service accounts for Seqera.
# Specifically, this is useful in an EKS context where a Kubernetes service account maps to an AWS IAM role.
module "seqera_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"                                  # Specifies the version of the module to use.
  count   = var.create_seqera_service_account ? 1 : 0 # Conditional creation based on the variable.

  role_name = local.seqera_irsa_role_name

  attach_vpc_cni_policy = true # Attach the VPC CNI policy to this IAM role.
  vpc_cni_enable_ipv4   = true # Enable IPv4 for VPC CNI.

  # Configuring the OpenID Connect (OIDC) provider for EKS. This is important for establishing the relationship 
  # between a Kubernetes service account and an AWS IAM role.
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.seqera_namespace_name}:${var.seqera_service_account_name}"]
    }
  }

  # IAM Policies to be attached to this role. 
  # It attaches the Amazon EKS CNI policy and the IAM policy created for Seqera.
  role_policy_arns = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    additional           = module.seqera_iam_policy[0].arn
  }

  tags = {
    Name = local.seqera_irsa_role_name # Assigning the role name as a tag.
  }
}

## Data to get the Ubunutu AMI ID
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd/ubuntu-focal-20.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

## EC2 Instance Module
module "ec2_instance" {
  source               = "terraform-aws-modules/ec2-instance/aws"
  version              = "5.5.0"
  create               = var.create_ec2_instance
  create_spot_instance = var.create_ec2_spot_instance

  name = var.ec2_instance_name

  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_instance_key_name
  monitoring                  = var.enable_ec2_instance_monitoring
  vpc_security_group_ids      = var.create_ec2_instance || var.create_ec2_spot_instance ? [module.ec2_sg[0].security_group_id] : []
  subnet_id                   = module.vpc.private_subnets[0]
  ami                         = var.ec2_instance_ami_id != "" ? var.ec2_instance_ami_id : data.aws_ami.ubuntu.id
  create_iam_instance_profile = var.create_ec2_instance_iam_instance_profile
  get_password_data           = var.get_ec2_instance_password_data
  iam_role_description        = var.ec2_instance_iam_role_description
  iam_role_name               = var.ec2_instance_iam_role_name
  iam_role_policies           = var.create_ec2_instance || var.create_ec2_spot_instance ? { "policy" = module.ec2_instance_profile_iam_policy[0].arn } : {}
  iam_role_tags               = var.default_tags

  # Default tags for VPC resources.
  tags = var.default_tags

  depends_on = [
    module.vpc
  ]
}
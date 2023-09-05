provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile, "--region", var.region]
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile, "--region", var.region]
  }
}

provider "helm" {
  debug = true
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile, "--region", var.region]
    }
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  azs                 = var.azs
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  elasticache_subnets = var.elasticache_subnets
  intra_subnets       = var.intra_subnets

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

  create_database_subnet_group       = var.create_database_subnet_group
  create_elasticache_subnet_group    = var.create_elasticache_subnet_group
  create_database_subnet_route_table = var.create_database_subnet_route_table
  one_nat_gateway_per_az             = var.one_nat_gateway_per_az

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = var.default_tags
}

locals {
  eks_aws_auth_roles = distinct(flatten(
    [
      for role in var.eks_aws_auth_roles : [
        {
          rolearn  = role
          username = element(split("/", role), 1)
          groups = [
            "system:masters"
          ]
        }
      ]
    ]
    )
  )

  eks_aws_auth_users = distinct(flatten(
    [
      for user in var.eks_aws_auth_users : [
        {
          userarn  = user
          username = element(split("/", user), 1)
          groups   = ["system:masters"]
        }
      ]
    ]
    )
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = var.eks_cluster_endpoint_public_access

  cluster_addons = var.eks_cluster_addons

  enable_irsa = var.eks_enable_irsa

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types               = var.eks_managed_node_group_defaults_instance_types
    iam_role_additional_policies = local.additional_policies
    subnet_ids                   = module.vpc.private_subnets
  }

  eks_managed_node_groups = {
    seqera = {
      min_size     = var.eks_managed_node_group_min_size
      max_size     = var.eks_managed_node_group_max_size
      desired_size = var.eks_managed_node_group_desired_size

      instance_types = var.eks_managed_node_group_defaults_instance_types
      capacity_type  = var.eks_managed_node_group_defaults_capacity_type
      subnet_ids     = module.vpc.private_subnets
    }
  }

  iam_role_additional_policies = local.additional_policies

  manage_aws_auth_configmap = var.eks_manage_aws_auth_configmap
  aws_auth_roles            = local.eks_aws_auth_roles
  aws_auth_users            = local.eks_aws_auth_users

  tags = var.default_tags
}

resource "kubernetes_namespace_v1" "this" {
  count = var.create_seqera_namespace ? 1 : 0 || var.create_seqera_service_account ? 1 : 0

  metadata {
    name = var.seqera_namespace_name
  }
}

resource "kubernetes_service_account_v1" "this" {
  count = var.create_seqera_service_account ? 1 : 0

  metadata {
    name      = var.seqera_service_account_name
    namespace = var.seqera_namespace_name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.seqera_irsa.iam_role_arn
    }
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace_v1.this]
}

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
    name = "autoDiscovery.clusterName"
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

resource "helm_release" "aws-ebs-csi-driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = var.ebs_csi_driver_version
  replace    = true
  atomic     = true
  wait       = true

  depends_on = [
    module.eks
  ]
}

resource "kubectl_manifest" "aws_loadbalancer_controller_crd" {
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

module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.db_security_group_name
  description = "Security group for access from seqera EKS cluster to seqera db"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  ingress_rules       = [var.db_ingress_rule]
}

module "redis_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.redis_security_group_name
  description = "Security group for access from seqera EKS cluster to seqera redis"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  ingress_rules       = [var.redis_ingress_rule]
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier                  = var.database_identifier
  manage_master_user_password = var.db_manage_master_user_password

  engine              = "mysql"
  engine_version      = var.db_engine_version
  instance_class      = var.db_instance_class
  allocated_storage   = var.db_allocated_storage
  skip_final_snapshot = var.db_skip_final_snapshot

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port
  password = var.db_password

  iam_database_authentication_enabled = var.db_iam_database_authentication_enabled

  vpc_security_group_ids = [module.db_sg.security_group_id]

  maintenance_window = var.db_maintenance_window
  backup_window      = var.db_backup_window

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval    = var.db_monitoring_interval
  monitoring_role_name   = var.db_monitoring_role_name
  create_monitoring_role = var.db_create_monitoring_role

  tags = var.default_tags

  # DB subnet group
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # DB parameter group
  family = var.db_family

  # DB option group
  major_engine_version = var.db_major_engine_version

  # Database Deletion Protection
  deletion_protection = var.db_deletion_protection

  parameters = var.db_parameters
  options    = var.db_options
}

module "memory_db" {
  source = "terraform-aws-modules/memory-db/aws"

  # Cluster
  name        = var.redis_cluster_name
  description = "seqera MemoryDB cluster"

  engine_version             = var.redis_engine_version
  auto_minor_version_upgrade = var.redis_auto_minor_version_upgrade
  node_type                  = var.redis_node_type
  num_shards                 = var.redis_num_shards
  num_replicas_per_shard     = var.redis_num_replicas_per_shard

  tls_enabled              = var.redis_tls_enabled
  security_group_ids       = [module.redis_sg.security_group_id]
  maintenance_window       = var.redis_maintenance_window
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  snapshot_window          = var.redis_snapshot_window
  create_acl               = var.redis_create_acl
  acl_name                 = var.redis_create_acl ? var.redis_acl_name : "open-access"

  # Users
  users = var.redis_create_acl ? var.redis_users : {}

  # Parameter group
  parameter_group_name        = var.redis_parameter_group_name
  parameter_group_description = var.redis_parameter_group_description
  parameter_group_family      = var.redis_parameter_group_family
  parameter_group_parameters  = var.redis_parameter_group_parameters
  parameter_group_tags        = var.redis_parameter_group_tags

  # Subnet group
  create_subnet_group      = var.redis_create_subnet_group
  subnet_group_name        = var.redis_subnet_group_name
  subnet_group_description = var.redis_subnet_group_description
  subnet_ids               = module.vpc.elasticache_subnets

  tags = var.default_tags
}

locals {
  seqera_irsa_role_name                       = "${var.seqera_irsa_role_name}-${var.cluster_name}-${var.region}"
  seqera_irsa_iam_policy_name                 = "${var.seqera_irsa_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_loadbalancer_controller_iam_policy_name = "${var.aws_loadbalancer_controller_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_cluster_autoscaler_iam_policy_name      = "${var.aws_cluster_autoscaler_iam_policy_name}-${var.cluster_name}-${var.region}"
  ebs_csi_driver_iam_policy_name              = "${var.ebs_csi_driver_iam_policy_name}-${var.cluster_name}-${var.region}"

# This code now has 7 conditions, where each one is an individual combination of the three boolean variables 
# (var.enable_aws_loadbalancer_controller, var.enable_ebs_csi_driver, and var.enable_aws_cluster_autoscaler). 
# The last condition simply defaults to an empty map if none of the three are enabled.

additional_policies = var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
    ebs_csi_driver_iam_policy              = module.ebs_csi_driver_iam_policy[0].arn
    aws_cluster_autoscaler_iam_policy      = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && !var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
    ebs_csi_driver_iam_policy              = module.ebs_csi_driver_iam_policy[0].arn
  } : var.enable_aws_loadbalancer_controller && !var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
    aws_cluster_autoscaler_iam_policy      = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : !var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    ebs_csi_driver_iam_policy              = module.ebs_csi_driver_iam_policy[0].arn
    aws_cluster_autoscaler_iam_policy      = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : var.enable_aws_loadbalancer_controller && !var.enable_ebs_csi_driver && !var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
  } : !var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && !var.enable_aws_cluster_autoscaler ? {
    ebs_csi_driver_iam_policy = module.ebs_csi_driver_iam_policy[0].arn
  } :!var.enable_aws_loadbalancer_controller && !var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    aws_cluster_autoscaler_iam_policy = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : {}  # This last case covers the scenario where none of the three are enabled
}

module "seqera_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = local.seqera_irsa_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for seqera service account to be able to interact with the required AWS services."

  policy = var.seqera_platform_service_account_iam_policy

  tags = var.default_tags
}

module "aws_loadbalancer_controller_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  count  = var.enable_aws_loadbalancer_controller ? 1 : 0

  name        = local.aws_loadbalancer_controller_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for AWS loadBalancer controller"

  policy = var.aws_loadbalancer_controller_iam_policy

  tags = var.default_tags
}

module "aws_cluster_autoscaler_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  count  = var.enable_aws_cluster_autoscaler ? 1 : 0

  name        = local.aws_cluster_autoscaler_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for AWS cluster autoscaler"

  policy = var.aws_cluster_autoscaler_iam_policy

  tags = var.default_tags
}

module "ebs_csi_driver_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  count  = var.enable_ebs_csi_driver ? 1 : 0

  name        = local.ebs_csi_driver_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for EBS CSI driver"

  policy = var.ebs_csi_driver_iam_policy

  tags = var.default_tags
}

module "seqera_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = local.seqera_irsa_role_name

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.seqera_namespace_name}:${var.seqera_service_account_name}"]
    }
  }

  role_policy_arns = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    additional           = module.seqera_iam_policy.arn
  }

  tags = {
    Name = local.seqera_irsa_role_name
  }
}


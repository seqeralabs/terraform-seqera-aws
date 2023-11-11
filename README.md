# Terraform Seqera Infrastructure Deployment Module

## This Terraform code deploys infrastructure resources using the following modules:

* [VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest): Creates a Virtual Private Cloud (VPC) with subnets, routing, and networking configurations.
* [EKS](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest): Provisions an Amazon Elastic Kubernetes Service (EKS) cluster with managed node groups.
* [Security-Group](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest): Sets up a security group for access from the EKS cluster to the database.
* [RDS](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest): Deploys an Amazon RDS database instance.
* [Elasticache-Redis](https://registry.terraform.io/modules/cloudposse/elasticache-redis/aws/latest): Creates a Redis MemoryDB cluster.

## Prerequisites
Before running this Terraform code, ensure you have the following prerequisites in place:

AWS CLI installed and configured with appropriate access credentials.
Terraform CLI installed on your local machine.

## Usage
Follow the steps below to deploy the infrastructure:

Example:
```hcl
## Module
module "terraform-seqera-module" {
  source  = "github.com/seqeralabs/terraform-seqera-module"
  aws_profile = "my-aws-profile"
  region  = "eu-west-2"

  ## VPC
  vpc_name = "my-seqera-tf-vpc"
  vpc_cidr = "10.0.0.0/16"

  azs                 = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets    = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]
  elasticache_subnets = ["10.0.107.0/24", "10.0.108.0/24", "10.0.109.0/24"]
  intra_subnets       = ["10.0.110.0/24", "10.0.111.0/24", "10.0.112.0/24"]

  ## EKS
  cluster_name    = "my-seqera-tf-cluster"
  cluster_version = "1.27"
  eks_managed_node_group_defaults_instance_types = ["t3.medium"]
  eks_managed_node_group_defaults_capacity_type = "ON_DEMAND"
  eks_aws_auth_roles = [
    "arn:aws:iam::1234567890123:role/MyIAMRole",
  ]

  eks_aws_auth_users = [
    "arn:aws:iam::1234567890123:user/MyIAMUSer"
  ]

  default_tags = {
    Environment = "myenvironment"
    ManagedBy   = "Terraform"
    Product     = "Seqera"
  }
}

## Outputs
output "database_url" {
  value = module.terraform-seqera-module.database_url
}

output "redis_url" {
  value = module.terraform-seqera-module.redis_url
}

output "seqera_irsa_role_name" {
  value = module.terraform-seqera-module.seqera_irsa_role_name
}
```

1. Clone this repository to your local machine.
2. Navigate to the project directory.
3. Initialize the Terraform configuration by running the following command:
```
terraform init
```
5. Review the variables in the variables.tf file and update them as per your requirements.
6. Run the Terraform plan command to see the execution plan:
```
terraform plan
```
If the plan looks good, apply the changes by running the following command:
```
terraform apply
```
7. Confirm the changes by typing yes when prompted.
Wait for Terraform to provision the infrastructure resources.

8. Once the deployment is complete, you will see the output values that provide information about the provisioned resources.

The following outputs will be displayed after successful deployment:

### Cleanup

To destroy the provisioned infrastructure and clean up resources, run the following command:
```
terraform destroy
```
Confirm the action by typing yes when prompted.

## License
This Terraform code is licensed under the Apache License

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.11.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.23.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.0.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.11.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.23.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_cluster_autoscaler_iam_policy"></a> [aws\_cluster\_autoscaler\_iam\_policy](#module\_aws\_cluster\_autoscaler\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.30.0 |
| <a name="module_aws_ebs_csi_driver_iam_policy"></a> [aws\_ebs\_csi\_driver\_iam\_policy](#module\_aws\_ebs\_csi\_driver\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.30.0 |
| <a name="module_aws_efs_csi_driver_iam_policy"></a> [aws\_efs\_csi\_driver\_iam\_policy](#module\_aws\_efs\_csi\_driver\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.30.0 |
| <a name="module_aws_loadbalancer_controller_iam_policy"></a> [aws\_loadbalancer\_controller\_iam\_policy](#module\_aws\_loadbalancer\_controller\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.30.0 |
| <a name="module_db"></a> [db](#module\_db) | terraform-aws-modules/rds/aws | 6.1.1 |
| <a name="module_db_sg"></a> [db\_sg](#module\_db\_sg) | terraform-aws-modules/security-group/aws | 5.1.0 |
| <a name="module_efs_sg"></a> [efs\_sg](#module\_efs\_sg) | terraform-aws-modules/security-group/aws | 5.1.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.19.0 |
| <a name="module_redis"></a> [redis](#module\_redis) | cloudposse/elasticache-redis/aws | 0.52.0 |
| <a name="module_redis_sg"></a> [redis\_sg](#module\_redis\_sg) | terraform-aws-modules/security-group/aws | 5.1.0 |
| <a name="module_seqera_iam_policy"></a> [seqera\_iam\_policy](#module\_seqera\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.30.0 |
| <a name="module_seqera_irsa"></a> [seqera\_irsa](#module\_seqera\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.30.0 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_efs_access_point.eks_efs_access_point](https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/resources/efs_access_point) | resource |
| [aws_efs_backup_policy.eks_efs](https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/resources/efs_backup_policy) | resource |
| [aws_efs_file_system.eks_efs](https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.eks_efs_mount_target](https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/resources/efs_mount_target) | resource |
| [helm_release.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/2.11.0/docs/resources/release) | resource |
| [helm_release.aws-efs-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/2.11.0/docs/resources/release) | resource |
| [helm_release.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/helm/2.11.0/docs/resources/release) | resource |
| [helm_release.aws_cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/2.11.0/docs/resources/release) | resource |
| [kubectl_manifest.aws_loadbalancer_controller_crd](https://registry.terraform.io/providers/gavinbunney/kubectl/1.14.0/docs/resources/manifest) | resource |
| [kubernetes_job_v1.seqera_schema_job](https://registry.terraform.io/providers/hashicorp/kubernetes/2.23.0/docs/resources/job_v1) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/2.23.0/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.db_app_password](https://registry.terraform.io/providers/hashicorp/kubernetes/2.23.0/docs/resources/secret_v1) | resource |
| [kubernetes_service_account_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/2.23.0/docs/resources/service_account_v1) | resource |
| [kubernetes_storage_class.efs_storage_class](https://registry.terraform.io/providers/hashicorp/kubernetes/2.23.0/docs/resources/storage_class) | resource |
| [random_password.db_app_password](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/password) | resource |
| [random_password.db_root_password](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/data-sources/eks_cluster_auth) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | A list of Availability Zones in the selected region. | `list(string)` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_database_subnets"></a> [database\_subnets](#input\_database\_subnets) | A list of subnet IDs for database subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_elasticache_subnets"></a> [elasticache\_subnets](#input\_elasticache\_subnets) | A list of subnet IDs for Elasticache subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_intra_subnets"></a> [intra\_subnets](#input\_intra\_subnets) | A list of subnet IDs for intra subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of subnet IDs for private subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of subnet IDs for public subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC. | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the Virtual Private Cloud (VPC) to be created. | `string` | n/a | yes |
| <a name="input_aws_cluster_autoscaler_iam_policy"></a> [aws\_cluster\_autoscaler\_iam\_policy](#input\_aws\_cluster\_autoscaler\_iam\_policy) | IAM policy for the AWS Cluster Autoscaler | `string` | `"{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"autoscaling:DescribeAutoScalingGroups\",\n        \"autoscaling:DescribeAutoScalingInstances\",\n        \"autoscaling:DescribeLaunchConfigurations\",\n        \"autoscaling:DescribeScalingActivities\",\n        \"autoscaling:DescribeTags\",\n        \"ec2:DescribeInstanceTypes\",\n        \"ec2:DescribeLaunchTemplateVersions\"\n      ],\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"autoscaling:SetDesiredCapacity\",\n        \"autoscaling:TerminateInstanceInAutoScalingGroup\",\n        \"ec2:DescribeImages\",\n        \"ec2:GetInstanceTypesFromInstanceRequirements\",\n        \"eks:DescribeNodegroup\"\n      ],\n      \"Resource\": [\"*\"]\n    }\n  ]\n}\n"` | no |
| <a name="input_aws_cluster_autoscaler_iam_policy_name"></a> [aws\_cluster\_autoscaler\_iam\_policy\_name](#input\_aws\_cluster\_autoscaler\_iam\_policy\_name) | The name of the IAM policy for the AWS Cluster Autoscaler. | `string` | `"aws-cluster-autoscaler-iam-policy"` | no |
| <a name="input_aws_cluster_autoscaler_version"></a> [aws\_cluster\_autoscaler\_version](#input\_aws\_cluster\_autoscaler\_version) | The version of the AWS Cluster Autoscaler to deploy. | `string` | `"9.29.3"` | no |
| <a name="input_aws_ebs_csi_driver_iam_policy"></a> [aws\_ebs\_csi\_driver\_iam\_policy](#input\_aws\_ebs\_csi\_driver\_iam\_policy) | IAM policy for the EBS CSI driver | `string` | `"{\n    \"Version\": \"2012-10-17\",\n    \"Statement\": [\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateSnapshot\",\n                \"ec2:AttachVolume\",\n                \"ec2:DetachVolume\",\n                \"ec2:ModifyVolume\",\n                \"ec2:DescribeAvailabilityZones\",\n                \"ec2:DescribeInstances\",\n                \"ec2:DescribeSnapshots\",\n                \"ec2:DescribeTags\",\n                \"ec2:DescribeVolumes\",\n                \"ec2:DescribeVolumesModifications\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:ec2:*:*:volume/*\",\n                \"arn:aws:ec2:*:*:snapshot/*\"\n            ],\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"ec2:CreateAction\": [\n                        \"CreateVolume\",\n                        \"CreateSnapshot\"\n                    ]\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:ec2:*:*:volume/*\",\n                \"arn:aws:ec2:*:*:snapshot/*\"\n            ]\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"aws:RequestTag/ebs.csi.aws.com/cluster\": \"true\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"aws:RequestTag/CSIVolumeName\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/ebs.csi.aws.com/cluster\": \"true\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/CSIVolumeName\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/kubernetes.io/created-for/pvc/name\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteSnapshot\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/CSIVolumeSnapshotName\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteSnapshot\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/ebs.csi.aws.com/cluster\": \"true\"\n                }\n            }\n        }\n    ]\n}\n"` | no |
| <a name="input_aws_ebs_csi_driver_iam_policy_name"></a> [aws\_ebs\_csi\_driver\_iam\_policy\_name](#input\_aws\_ebs\_csi\_driver\_iam\_policy\_name) | The name of the IAM policy for the EBS CSI driver. | `string` | `"ebs-csi-driver-iam-policy"` | no |
| <a name="input_aws_ebs_csi_driver_version"></a> [aws\_ebs\_csi\_driver\_version](#input\_aws\_ebs\_csi\_driver\_version) | The version of the EBS CSI driver to deploy. | `string` | `"2.13.0"` | no |
| <a name="input_aws_efs_csi_driver_backup_policy_status"></a> [aws\_efs\_csi\_driver\_backup\_policy\_status](#input\_aws\_efs\_csi\_driver\_backup\_policy\_status) | The backup policy status of the EFS file system. | `string` | `"ENABLED"` | no |
| <a name="input_aws_efs_csi_driver_creation_token_name"></a> [aws\_efs\_csi\_driver\_creation\_token\_name](#input\_aws\_efs\_csi\_driver\_creation\_token\_name) | The creation token for the EFS file system. | `string` | `"seqera-efs-csi-driver"` | no |
| <a name="input_aws_efs_csi_driver_iam_policy"></a> [aws\_efs\_csi\_driver\_iam\_policy](#input\_aws\_efs\_csi\_driver\_iam\_policy) | IAM policy for the AWS EFS CSI driver | `string` | `"{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"elasticfilesystem:DescribeAccessPoints\",\n        \"elasticfilesystem:DescribeFileSystems\",\n        \"elasticfilesystem:DescribeMountTargets\",\n        \"ec2:DescribeAvailabilityZones\"\n      ],\n      \"Resource\": \"*\"\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"elasticfilesystem:CreateAccessPoint\"\n      ],\n      \"Resource\": \"*\",\n      \"Condition\": {\n        \"StringLike\": {\n          \"aws:RequestTag/efs.csi.aws.com/cluster\": \"true\"\n        }\n      }\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"elasticfilesystem:TagResource\"\n      ],\n      \"Resource\": \"*\",\n      \"Condition\": {\n        \"StringLike\": {\n          \"aws:ResourceTag/efs.csi.aws.com/cluster\": \"true\"\n        }\n      }\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": \"elasticfilesystem:DeleteAccessPoint\",\n      \"Resource\": \"*\",\n      \"Condition\": {\n        \"StringEquals\": {\n          \"aws:ResourceTag/efs.csi.aws.com/cluster\": \"true\"\n        }\n      }\n    }\n  ]\n}\n"` | no |
| <a name="input_aws_efs_csi_driver_iam_policy_name"></a> [aws\_efs\_csi\_driver\_iam\_policy\_name](#input\_aws\_efs\_csi\_driver\_iam\_policy\_name) | The name of the IAM policy for the AWS EFS CSI driver. | `string` | `"aws-efs-csi-driver-iam-policy"` | no |
| <a name="input_aws_efs_csi_driver_performance_mode"></a> [aws\_efs\_csi\_driver\_performance\_mode](#input\_aws\_efs\_csi\_driver\_performance\_mode) | The performance mode of the EFS file system. | `string` | `"generalPurpose"` | no |
| <a name="input_aws_efs_csi_driver_security_group_ingress_rule_name"></a> [aws\_efs\_csi\_driver\_security\_group\_ingress\_rule\_name](#input\_aws\_efs\_csi\_driver\_security\_group\_ingress\_rule\_name) | The name of the security group ingress rule for the AWS EFS CSI driver. | `string` | `"nfs-tcp"` | no |
| <a name="input_aws_efs_csi_driver_security_group_name"></a> [aws\_efs\_csi\_driver\_security\_group\_name](#input\_aws\_efs\_csi\_driver\_security\_group\_name) | The name of the security group for the AWS EFS CSI driver. | `string` | `"aws-efs-csi-driver-sg"` | no |
| <a name="input_aws_efs_csi_driver_storage_class_name"></a> [aws\_efs\_csi\_driver\_storage\_class\_name](#input\_aws\_efs\_csi\_driver\_storage\_class\_name) | The name of the storage class for the EFS file system. | `string` | `"efs-sc"` | no |
| <a name="input_aws_efs_csi_driver_storage_class_parameters"></a> [aws\_efs\_csi\_driver\_storage\_class\_parameters](#input\_aws\_efs\_csi\_driver\_storage\_class\_parameters) | The parameters for the storage class for the EFS file system. | `map(string)` | <pre>{<br>  "basePath": "/dynamic_provisioning",<br>  "directoryPerms": "700",<br>  "gidRangeEnd": "2000",<br>  "gidRangeStart": "1000",<br>  "provisioningMode": "efs-ap"<br>}</pre> | no |
| <a name="input_aws_efs_csi_driver_storage_class_reclaim_policy"></a> [aws\_efs\_csi\_driver\_storage\_class\_reclaim\_policy](#input\_aws\_efs\_csi\_driver\_storage\_class\_reclaim\_policy) | The reclaim policy for the EFS file system. | `string` | `"Retain"` | no |
| <a name="input_aws_efs_csi_driver_storage_class_storage_provisioner_name"></a> [aws\_efs\_csi\_driver\_storage\_class\_storage\_provisioner\_name](#input\_aws\_efs\_csi\_driver\_storage\_class\_storage\_provisioner\_name) | The storage provisioner for the EFS file system. | `string` | `"efs.csi.aws.com"` | no |
| <a name="input_aws_efs_csi_driver_version"></a> [aws\_efs\_csi\_driver\_version](#input\_aws\_efs\_csi\_driver\_version) | The version of the AWS EFS CSI driver to deploy. | `string` | `"2.4.9"` | no |
| <a name="input_aws_loadbalancer_controller_iam_policy"></a> [aws\_loadbalancer\_controller\_iam\_policy](#input\_aws\_loadbalancer\_controller\_iam\_policy) | IAM policy for the AWS LoadBalancer Controller | `string` | `"{\n    \"Version\": \"2012-10-17\",\n    \"Statement\": [\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"iam:CreateServiceLinkedRole\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"iam:AWSServiceName\": \"elasticloadbalancing.amazonaws.com\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DescribeAccountAttributes\",\n                \"ec2:DescribeAddresses\",\n                \"ec2:DescribeAvailabilityZones\",\n                \"ec2:DescribeInternetGateways\",\n                \"ec2:DescribeVpcs\",\n                \"ec2:DescribeVpcPeeringConnections\",\n                \"ec2:DescribeSubnets\",\n                \"ec2:DescribeSecurityGroups\",\n                \"ec2:DescribeInstances\",\n                \"ec2:DescribeNetworkInterfaces\",\n                \"ec2:DescribeTags\",\n                \"ec2:GetCoipPoolUsage\",\n                \"ec2:DescribeCoipPools\",\n                \"elasticloadbalancing:DescribeLoadBalancers\",\n                \"elasticloadbalancing:DescribeLoadBalancerAttributes\",\n                \"elasticloadbalancing:DescribeListeners\",\n                \"elasticloadbalancing:DescribeListenerCertificates\",\n                \"elasticloadbalancing:DescribeSSLPolicies\",\n                \"elasticloadbalancing:DescribeRules\",\n                \"elasticloadbalancing:DescribeTargetGroups\",\n                \"elasticloadbalancing:DescribeTargetGroupAttributes\",\n                \"elasticloadbalancing:DescribeTargetHealth\",\n                \"elasticloadbalancing:DescribeTags\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"cognito-idp:DescribeUserPoolClient\",\n                \"acm:ListCertificates\",\n                \"acm:DescribeCertificate\",\n                \"iam:ListServerCertificates\",\n                \"iam:GetServerCertificate\",\n                \"waf-regional:GetWebACL\",\n                \"waf-regional:GetWebACLForResource\",\n                \"waf-regional:AssociateWebACL\",\n                \"waf-regional:DisassociateWebACL\",\n                \"wafv2:GetWebACL\",\n                \"wafv2:GetWebACLForResource\",\n                \"wafv2:AssociateWebACL\",\n                \"wafv2:DisassociateWebACL\",\n                \"shield:GetSubscriptionState\",\n                \"shield:DescribeProtection\",\n                \"shield:CreateProtection\",\n                \"shield:DeleteProtection\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:AuthorizeSecurityGroupIngress\",\n                \"ec2:RevokeSecurityGroupIngress\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateSecurityGroup\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateTags\"\n            ],\n            \"Resource\": \"arn:aws:ec2:*:*:security-group/*\",\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"ec2:CreateAction\": \"CreateSecurityGroup\"\n                },\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateTags\",\n                \"ec2:DeleteTags\"\n            ],\n            \"Resource\": \"arn:aws:ec2:*:*:security-group/*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"true\",\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:AuthorizeSecurityGroupIngress\",\n                \"ec2:RevokeSecurityGroupIngress\",\n                \"ec2:DeleteSecurityGroup\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:CreateLoadBalancer\",\n                \"elasticloadbalancing:CreateTargetGroup\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:CreateListener\",\n                \"elasticloadbalancing:DeleteListener\",\n                \"elasticloadbalancing:CreateRule\",\n                \"elasticloadbalancing:DeleteRule\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:AddTags\",\n                \"elasticloadbalancing:RemoveTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*\"\n            ],\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"true\",\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:AddTags\",\n                \"elasticloadbalancing:RemoveTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*\"\n            ]\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:ModifyLoadBalancerAttributes\",\n                \"elasticloadbalancing:SetIpAddressType\",\n                \"elasticloadbalancing:SetSecurityGroups\",\n                \"elasticloadbalancing:SetSubnets\",\n                \"elasticloadbalancing:DeleteLoadBalancer\",\n                \"elasticloadbalancing:ModifyTargetGroup\",\n                \"elasticloadbalancing:ModifyTargetGroupAttributes\",\n                \"elasticloadbalancing:DeleteTargetGroup\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:AddTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*\"\n            ],\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"elasticloadbalancing:CreateAction\": [\n                        \"CreateTargetGroup\",\n                        \"CreateLoadBalancer\"\n                    ]\n                },\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:RegisterTargets\",\n                \"elasticloadbalancing:DeregisterTargets\"\n            ],\n            \"Resource\": \"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:SetWebAcl\",\n                \"elasticloadbalancing:ModifyListener\",\n                \"elasticloadbalancing:AddListenerCertificates\",\n                \"elasticloadbalancing:RemoveListenerCertificates\",\n                \"elasticloadbalancing:ModifyRule\"\n            ],\n            \"Resource\": \"*\"\n        }\n    ]\n}\n\n"` | no |
| <a name="input_aws_loadbalancer_controller_iam_policy_name"></a> [aws\_loadbalancer\_controller\_iam\_policy\_name](#input\_aws\_loadbalancer\_controller\_iam\_policy\_name) | The name of the IAM policy for the AWS LoadBalancer Controller | `string` | `"aws-loadbalancer-controller-iam-policy"` | no |
| <a name="input_aws_loadbalancer_controller_version"></a> [aws\_loadbalancer\_controller\_version](#input\_aws\_loadbalancer\_controller\_version) | The version of the AWS LoadBalancer Controller to deploy | `string` | `"1.6.0"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile used for authentication when interacting with AWS resources. | `string` | `"default"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The version of Kubernetes to use for the EKS cluster. | `string` | `"1.27"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Determines whether a database subnet group should be created. | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Determines whether a subnet route table should be created for the database subnets. | `bool` | `true` | no |
| <a name="input_create_db_cluster"></a> [create\_db\_cluster](#input\_create\_db\_cluster) | Determines whether the database cluster should be created. | `bool` | `true` | no |
| <a name="input_create_db_password_secret"></a> [create\_db\_password\_secret](#input\_create\_db\_password\_secret) | Determines whether a secret should be created for the database password. | `bool` | `true` | no |
| <a name="input_create_redis_cluster"></a> [create\_redis\_cluster](#input\_create\_redis\_cluster) | Determines whether to create a Redis cluster. | `bool` | `true` | no |
| <a name="input_create_seqera_namespace"></a> [create\_seqera\_namespace](#input\_create\_seqera\_namespace) | Determines whether to create the Seqera namespace. | `bool` | `true` | no |
| <a name="input_create_seqera_service_account"></a> [create\_seqera\_service\_account](#input\_create\_seqera\_service\_account) | Determines whether to create the Seqera service account. | `bool` | `true` | no |
| <a name="input_database_identifier"></a> [database\_identifier](#input\_database\_identifier) | The identifier for the database. | `string` | `"seqera-db"` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | The allocated storage size for the database. | `number` | `10` | no |
| <a name="input_db_app_password"></a> [db\_app\_password](#input\_db\_app\_password) | Password for the Seqera DB user. | `string` | `""` | no |
| <a name="input_db_app_schema_name"></a> [db\_app\_schema\_name](#input\_db\_app\_schema\_name) | The name of the database. | `string` | `"tower"` | no |
| <a name="input_db_app_username"></a> [db\_app\_username](#input\_db\_app\_username) | The username for the database. | `string` | `"seqera"` | no |
| <a name="input_db_backup_window"></a> [db\_backup\_window](#input\_db\_backup\_window) | The backup window for the database. | `string` | `"03:00-06:00"` | no |
| <a name="input_db_create_monitoring_role"></a> [db\_create\_monitoring\_role](#input\_db\_create\_monitoring\_role) | Determines whether the monitoring role should be created. | `bool` | `false` | no |
| <a name="input_db_deletion_protection"></a> [db\_deletion\_protection](#input\_db\_deletion\_protection) | Determines whether deletion protection is enabled for the database. | `bool` | `false` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | The version of the database engine. | `string` | `"5.7"` | no |
| <a name="input_db_family"></a> [db\_family](#input\_db\_family) | The family of the database engine. | `string` | `"mysql5.7"` | no |
| <a name="input_db_iam_database_authentication_enabled"></a> [db\_iam\_database\_authentication\_enabled](#input\_db\_iam\_database\_authentication\_enabled) | Determines whether IAM database authentication is enabled for the database. | `bool` | `false` | no |
| <a name="input_db_ingress_rule_name"></a> [db\_ingress\_rule\_name](#input\_db\_ingress\_rule\_name) | The ingress rule for the database. | `string` | `"mysql-tcp"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | The instance class for the database. | `string` | `"db.r5.xlarge"` | no |
| <a name="input_db_maintenance_window"></a> [db\_maintenance\_window](#input\_db\_maintenance\_window) | The maintenance window for the database. | `string` | `"Mon:00:00-Mon:03:00"` | no |
| <a name="input_db_major_engine_version"></a> [db\_major\_engine\_version](#input\_db\_major\_engine\_version) | The major version of the database engine. | `string` | `"5.7"` | no |
| <a name="input_db_manage_master_user_password"></a> [db\_manage\_master\_user\_password](#input\_db\_manage\_master\_user\_password) | Determines whether the master user password should be managed. | `bool` | `false` | no |
| <a name="input_db_monitoring_interval"></a> [db\_monitoring\_interval](#input\_db\_monitoring\_interval) | The monitoring interval for the database. | `string` | `"0"` | no |
| <a name="input_db_monitoring_role_name"></a> [db\_monitoring\_role\_name](#input\_db\_monitoring\_role\_name) | The name of the IAM role used for database monitoring. | `string` | `"SeqeraRDSMonitoringRole"` | no |
| <a name="input_db_options"></a> [db\_options](#input\_db\_options) | The list of database options. | <pre>list(object({<br>    option_name = string<br>    option_settings = list(object({<br>      name  = string<br>      value = string<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "option_name": "MARIADB_AUDIT_PLUGIN",<br>    "option_settings": [<br>      {<br>        "name": "SERVER_AUDIT_EVENTS",<br>        "value": "CONNECT"<br>      },<br>      {<br>        "name": "SERVER_AUDIT_FILE_ROTATIONS",<br>        "value": "37"<br>      }<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_db_parameters"></a> [db\_parameters](#input\_db\_parameters) | The list of database parameters. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "character_set_client",<br>    "value": "utf8mb4"<br>  },<br>  {<br>    "name": "character_set_server",<br>    "value": "utf8mb4"<br>  }<br>]</pre> | no |
| <a name="input_db_password_secret_name"></a> [db\_password\_secret\_name](#input\_db\_password\_secret\_name) | The name of the secret for the database password. | `string` | `"seqera-db-password"` | no |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | The port for the database. | `string` | `"3306"` | no |
| <a name="input_db_root_password"></a> [db\_root\_password](#input\_db\_root\_password) | The master password for the database. | `string` | `""` | no |
| <a name="input_db_root_username"></a> [db\_root\_username](#input\_db\_root\_username) | The master username for the database. | `string` | `"root"` | no |
| <a name="input_db_security_group_name"></a> [db\_security\_group\_name](#input\_db\_security\_group\_name) | The name of the security group for the database. | `string` | `"seqera_db_security_group"` | no |
| <a name="input_db_setup_job_image"></a> [db\_setup\_job\_image](#input\_db\_setup\_job\_image) | The image for the database setup job. | `string` | `"mysql:8.0.35-debian"` | no |
| <a name="input_db_setup_job_name"></a> [db\_setup\_job\_name](#input\_db\_setup\_job\_name) | The name of the database setup job. | `string` | `"seqera-db-setup-job"` | no |
| <a name="input_db_skip_final_snapshot"></a> [db\_skip\_final\_snapshot](#input\_db\_skip\_final\_snapshot) | Determines whether a final snapshot should be created when the database is deleted. | `bool` | `true` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to be applied to the provisioned resources. | `map(string)` | <pre>{<br>  "ManagedBy": "Terraform",<br>  "Product": "Seqera Platform"<br>}</pre> | no |
| <a name="input_eks_aws_auth_roles"></a> [eks\_aws\_auth\_roles](#input\_eks\_aws\_auth\_roles) | List of roles ARNs to add to the aws-auth config map | `list(string)` | `[]` | no |
| <a name="input_eks_aws_auth_users"></a> [eks\_aws\_auth\_users](#input\_eks\_aws\_auth\_users) | List of users ARNs to add to the aws-auth config map | `list(string)` | `[]` | no |
| <a name="input_eks_cluster_addons"></a> [eks\_cluster\_addons](#input\_eks\_cluster\_addons) | Addons to be enabled for the EKS cluster. | <pre>map(object({<br>    most_recent = bool<br>  }))</pre> | <pre>{<br>  "coredns": {<br>    "most_recent": true<br>  },<br>  "kube-proxy": {<br>    "most_recent": true<br>  },<br>  "vpc-cni": {<br>    "most_recent": true<br>  }<br>}</pre> | no |
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | Determines whether the EKS cluster endpoint is publicly accessible. | `bool` | `true` | no |
| <a name="input_eks_enable_irsa"></a> [eks\_enable\_irsa](#input\_eks\_enable\_irsa) | Determines whether to create an OpenID Connect Provider for EKS to enable IRSA | `bool` | `true` | no |
| <a name="input_eks_manage_aws_auth_configmap"></a> [eks\_manage\_aws\_auth\_configmap](#input\_eks\_manage\_aws\_auth\_configmap) | Determines whether to manage the aws-auth ConfigMap. | `bool` | `true` | no |
| <a name="input_eks_managed_node_group_defaults_capacity_type"></a> [eks\_managed\_node\_group\_defaults\_capacity\_type](#input\_eks\_managed\_node\_group\_defaults\_capacity\_type) | The capacity type for the default managed node group. | `string` | `"ON_DEMAND"` | no |
| <a name="input_eks_managed_node_group_defaults_instance_types"></a> [eks\_managed\_node\_group\_defaults\_instance\_types](#input\_eks\_managed\_node\_group\_defaults\_instance\_types) | A list of EC2 instance types for the default managed node group. | `list(string)` | <pre>[<br>  "m5a.2xlarge"<br>]</pre> | no |
| <a name="input_enable_aws_cluster_autoscaler"></a> [enable\_aws\_cluster\_autoscaler](#input\_enable\_aws\_cluster\_autoscaler) | Determines whether the AWS Cluster Autoscaler should be deployed. | `bool` | `false` | no |
| <a name="input_enable_aws_ebs_csi_driver"></a> [enable\_aws\_ebs\_csi\_driver](#input\_enable\_aws\_ebs\_csi\_driver) | Determines whether the EBS CSI driver should be deployed. | `bool` | `false` | no |
| <a name="input_enable_aws_efs_csi_driver"></a> [enable\_aws\_efs\_csi\_driver](#input\_enable\_aws\_efs\_csi\_driver) | Determines whether the AWS EFS CSI driver should be deployed. | `bool` | `false` | no |
| <a name="input_enable_aws_loadbalancer_controller"></a> [enable\_aws\_loadbalancer\_controller](#input\_enable\_aws\_loadbalancer\_controller) | Determines whether the AWS LoadBalancer Controller should be deployed. | `bool` | `true` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Determines whether instances in the VPC receive DNS hostnames. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Determines whether DNS resolution is supported for the VPC. | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Determines whether NAT gateways should be provisioned. | `bool` | `true` | no |
| <a name="input_enable_vpn_gateway"></a> [enable\_vpn\_gateway](#input\_enable\_vpn\_gateway) | Determines whether a VPN gateway should be provisioned. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment in which the infrastructure is being deployed. | `string` | `""` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Determines whether each Availability Zone should have a dedicated NAT gateway. | `bool` | `true` | no |
| <a name="input_redis_apply_immediately"></a> [redis\_apply\_immediately](#input\_redis\_apply\_immediately) | Determines whether changes should be applied immediately for Redis. | `bool` | `true` | no |
| <a name="input_redis_at_rest_encryption_enabled"></a> [redis\_at\_rest\_encryption\_enabled](#input\_redis\_at\_rest\_encryption\_enabled) | Determines whether encryption at rest is enabled for Redis. | `bool` | `false` | no |
| <a name="input_redis_auto_minor_version_upgrade"></a> [redis\_auto\_minor\_version\_upgrade](#input\_redis\_auto\_minor\_version\_upgrade) | Determines whether automatic minor version upgrades are enabled for Redis. | `bool` | `false` | no |
| <a name="input_redis_automatic_failover_enabled"></a> [redis\_automatic\_failover\_enabled](#input\_redis\_automatic\_failover\_enabled) | Determines whether automatic failover is enabled for Redis. | `bool` | `false` | no |
| <a name="input_redis_cluster_description"></a> [redis\_cluster\_description](#input\_redis\_cluster\_description) | The description of the Redis cluster. | `string` | `"Seqera Redis cluster"` | no |
| <a name="input_redis_cluster_name"></a> [redis\_cluster\_name](#input\_redis\_cluster\_name) | The name of the Redis cluster. | `string` | `"seqera-redis"` | no |
| <a name="input_redis_cluster_size"></a> [redis\_cluster\_size](#input\_redis\_cluster\_size) | The size of the Redis cluster. | `number` | `1` | no |
| <a name="input_redis_create_subnet_group"></a> [redis\_create\_subnet\_group](#input\_redis\_create\_subnet\_group) | Determines whether to create a Redis subnet group. | `bool` | `true` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | The version of the Redis engine. | `string` | `"6.2"` | no |
| <a name="input_redis_family"></a> [redis\_family](#input\_redis\_family) | The family of the Redis engine. | `string` | `"redis6.x"` | no |
| <a name="input_redis_ingress_rule"></a> [redis\_ingress\_rule](#input\_redis\_ingress\_rule) | The ingress rule for the Redis cluster. | `string` | `"redis-tcp"` | no |
| <a name="input_redis_instance_type"></a> [redis\_instance\_type](#input\_redis\_instance\_type) | The Redis node type. | `string` | `"cache.t2.small"` | no |
| <a name="input_redis_maintenance_window"></a> [redis\_maintenance\_window](#input\_redis\_maintenance\_window) | The maintenance window for the Redis cluster. | `string` | `"sun:23:00-mon:01:30"` | no |
| <a name="input_redis_parameter_group_description"></a> [redis\_parameter\_group\_description](#input\_redis\_parameter\_group\_description) | The description of the Redis parameter group. | `string` | `"Redis Redis parameter group"` | no |
| <a name="input_redis_parameters"></a> [redis\_parameters](#input\_redis\_parameters) | The list of Redis parameters. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "notify-keyspace-events",<br>    "value": "lK"<br>  }<br>]</pre> | no |
| <a name="input_redis_security_group_name"></a> [redis\_security\_group\_name](#input\_redis\_security\_group\_name) | The name of the security group for Redis. | `string` | `"seqera_redis_security_group"` | no |
| <a name="input_redis_snapshot_retention_limit"></a> [redis\_snapshot\_retention\_limit](#input\_redis\_snapshot\_retention\_limit) | The number of days to retain Redis snapshots. | `number` | `7` | no |
| <a name="input_redis_snapshot_window"></a> [redis\_snapshot\_window](#input\_redis\_snapshot\_window) | The window during which Redis snapshots are taken. | `string` | `"05:00-09:00"` | no |
| <a name="input_redis_subnet_group_description"></a> [redis\_subnet\_group\_description](#input\_redis\_subnet\_group\_description) | The description of the Redis subnet group. | `string` | `"Seqera Redis subnet group"` | no |
| <a name="input_redis_subnet_group_name"></a> [redis\_subnet\_group\_name](#input\_redis\_subnet\_group\_name) | The name of the Redis subnet group. | `string` | `"seqera-redis-subnetgroup"` | no |
| <a name="input_redis_transit_encryption_enabled"></a> [redis\_transit\_encryption\_enabled](#input\_redis\_transit\_encryption\_enabled) | Determines whether encryption in transit is enabled for Redis. | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region in which the resources will be provisioned. | `string` | `""` | no |
| <a name="input_seqera_irsa_iam_policy_name"></a> [seqera\_irsa\_iam\_policy\_name](#input\_seqera\_irsa\_iam\_policy\_name) | The name of the IAM policy for IRSA. | `string` | `"seqera-irsa-iam-policy"` | no |
| <a name="input_seqera_irsa_role_name"></a> [seqera\_irsa\_role\_name](#input\_seqera\_irsa\_role\_name) | The name of the IAM role for IRSA. | `string` | `"seqera-irsa-role"` | no |
| <a name="input_seqera_managed_node_group_defaults_capacity_type"></a> [seqera\_managed\_node\_group\_defaults\_capacity\_type](#input\_seqera\_managed\_node\_group\_defaults\_capacity\_type) | The capacity type for the Seqera managed node group. | `string` | `"ON_DEMAND"` | no |
| <a name="input_seqera_managed_node_group_defaults_instance_types"></a> [seqera\_managed\_node\_group\_defaults\_instance\_types](#input\_seqera\_managed\_node\_group\_defaults\_instance\_types) | A list of EC2 instance types for the Seqera managed node group. | `list(string)` | <pre>[<br>  "m5a.2xlarge"<br>]</pre> | no |
| <a name="input_seqera_managed_node_group_desired_size"></a> [seqera\_managed\_node\_group\_desired\_size](#input\_seqera\_managed\_node\_group\_desired\_size) | The desired size of the EKS managed node group. | `number` | `2` | no |
| <a name="input_seqera_managed_node_group_labels"></a> [seqera\_managed\_node\_group\_labels](#input\_seqera\_managed\_node\_group\_labels) | Labels to be applied to the Seqera EKS managed node group. | `map(string)` | `{}` | no |
| <a name="input_seqera_managed_node_group_max_size"></a> [seqera\_managed\_node\_group\_max\_size](#input\_seqera\_managed\_node\_group\_max\_size) | The maximum size of the EKS managed node group. | `number` | `4` | no |
| <a name="input_seqera_managed_node_group_min_size"></a> [seqera\_managed\_node\_group\_min\_size](#input\_seqera\_managed\_node\_group\_min\_size) | The minimum size of the EKS managed node group. | `number` | `2` | no |
| <a name="input_seqera_namespace_name"></a> [seqera\_namespace\_name](#input\_seqera\_namespace\_name) | The name of the namespace used to deploy Seqera platform manifests. | `string` | `"seqera-platform"` | no |
| <a name="input_seqera_platform_service_account_iam_policy"></a> [seqera\_platform\_service\_account\_iam\_policy](#input\_seqera\_platform\_service\_account\_iam\_policy) | IAM policy for the Seqera service account | `string` | `"{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n      {\n          \"Sid\": \"TowerForge0\",\n          \"Effect\": \"Allow\",\n          \"Action\": [\n              \"ssm:GetParameters\",\n              \"ses:SendRawEmail\",\n              \"iam:CreateInstanceProfile\",\n              \"iam:DeleteInstanceProfile\",\n              \"iam:GetRole\",\n              \"iam:RemoveRoleFromInstanceProfile\",\n              \"iam:CreateRole\",\n              \"iam:DeleteRole\",\n              \"iam:AttachRolePolicy\",\n              \"iam:PutRolePolicy\",\n              \"iam:AddRoleToInstanceProfile\",\n              \"iam:PassRole\",\n              \"iam:DetachRolePolicy\",\n              \"iam:ListAttachedRolePolicies\",\n              \"iam:DeleteRolePolicy\",\n              \"iam:ListRolePolicies\",\n              \"iam:TagRole\",\n              \"iam:TagInstanceProfile\",\n              \"batch:CreateComputeEnvironment\",\n              \"batch:DescribeComputeEnvironments\",\n              \"batch:CreateJobQueue\",\n              \"batch:DescribeJobQueues\",\n              \"batch:UpdateComputeEnvironment\",\n              \"batch:DeleteComputeEnvironment\",\n              \"batch:UpdateJobQueue\",\n              \"batch:DeleteJobQueue\",\n              \"batch:TagResource\",\n              \"fsx:DeleteFileSystem\",\n              \"fsx:DescribeFileSystems\",\n              \"fsx:CreateFileSystem\",\n              \"fsx:TagResource\",\n              \"ec2:DescribeSecurityGroups\",\n              \"ec2:DescribeAccountAttributes\",\n              \"ec2:DescribeSubnets\",\n              \"ec2:DescribeLaunchTemplates\",\n              \"ec2:DescribeLaunchTemplateVersions\", \n              \"ec2:CreateLaunchTemplate\",\n              \"ec2:DeleteLaunchTemplate\",\n              \"ec2:DescribeKeyPairs\",\n              \"ec2:DescribeVpcs\",\n              \"ec2:DescribeInstanceTypeOfferings\",\n              \"ec2:GetEbsEncryptionByDefault\",\n              \"elasticfilesystem:DescribeMountTargets\",\n              \"elasticfilesystem:CreateMountTarget\",\n              \"elasticfilesystem:CreateFileSystem\",\n              \"elasticfilesystem:DescribeFileSystems\",\n              \"elasticfilesystem:DeleteMountTarget\",\n              \"elasticfilesystem:DeleteFileSystem\",\n              \"elasticfilesystem:UpdateFileSystem\",\n              \"elasticfilesystem:PutLifecycleConfiguration\",\n              \"elasticfilesystem:TagResource\"\n          ],\n          \"Resource\": \"*\"\n      },\n      {\n          \"Sid\": \"TowerLaunch0\",\n          \"Effect\": \"Allow\",\n          \"Action\": [\n              \"s3:Get*\",\n              \"s3:List*\",\n              \"batch:DescribeJobQueues\",\n              \"batch:CancelJob\",\n              \"batch:SubmitJob\",\n              \"batch:ListJobs\",\n              \"batch:DescribeComputeEnvironments\",\n              \"batch:TerminateJob\",\n              \"batch:DescribeJobs\",\n              \"batch:RegisterJobDefinition\",\n              \"batch:DescribeJobDefinitions\",\n              \"ecs:DescribeTasks\",\n              \"ec2:DescribeInstances\",\n              \"ec2:DescribeInstanceTypes\",\n              \"ec2:DescribeInstanceAttribute\",\n              \"ecs:DescribeContainerInstances\",\n              \"ec2:DescribeInstanceStatus\",\n              \"ec2:DescribeImages\",\n              \"logs:Describe*\",\n              \"logs:Get*\",\n              \"logs:List*\",\n              \"logs:StartQuery\",\n              \"logs:StopQuery\",\n              \"logs:TestMetricFilter\",\n              \"logs:FilterLogEvents\"\n          ],\n          \"Resource\": \"*\"\n      }\n  ]\n}\n"` | no |
| <a name="input_seqera_service_account_name"></a> [seqera\_service\_account\_name](#input\_seqera\_service\_account\_name) | Name for the Seqera platform service account | `string` | `"seqera-sa"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_url"></a> [database\_url](#output\_database\_url) | Endpoint address for the primary RDS database instance. |
| <a name="output_redis_url"></a> [redis\_url](#output\_redis\_url) | Endpoint address for the Redis cluster. If not available, returns null. |
| <a name="output_seqera_irsa_role_name"></a> [seqera\_irsa\_role\_name](#output\_seqera\_irsa\_role\_name) | IAM role name associated with Seqera IRSA (IAM Roles for Service Accounts). |
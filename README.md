# Terraform Seqera Infrastructure Deployment Module

## This Terraform code deploys infrastructure resources using the following modules:

* vpc module: Creates a Virtual Private Cloud (VPC) with subnets, routing, and networking configurations.
* eks module: Provisions an Amazon Elastic Kubernetes Service (EKS) cluster with managed node groups.
* db\_sg module: Sets up a security group for access from the EKS cluster to the database.
* redis\_sg module: Configures a security group for access from the EKS cluster to Redis.
* db module: Deploys an Amazon RDS database instance.
* memory\_db module: Creates a Redis MemoryDB cluster.

## Prerequisites
Before running this Terraform code, ensure you have the following prerequisites in place:

AWS CLI installed and configured with appropriate access credentials.
Terraform CLI installed on your local machine.

## Usage
Follow the steps below to deploy the infrastructure:

Example:
```
## Module
module "terraform-seqera-module" {
  source  = "github.com/seqeralabs/terraform-seqera-module"
  aws_profile = "my-aws-profile"
  region  = "eu-west-2"

  ## VPC
  vpc_name = "my-tower-tf-vpc"
  vpc_cidr = "10.0.0.0/16"

  azs                 = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets    = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]
  elasticache_subnets = ["10.0.107.0/24", "10.0.108.0/24", "10.0.109.0/24"]
  intra_subnets       = ["10.0.110.0/24", "10.0.111.0/24", "10.0.112.0/24"]

  ## EKS
  cluster_name    = "my-tower-tf-cluster"
  cluster_version = "1.27"
  eks_managed_node_group_defaults_instance_types = ["t3.medium"]
  eks_managed_node_group_defaults_capacity_type = "ON_DEMAND"
  eks_aws_auth_roles = [
    "arn:aws:iam::1234567890123:role/MyIAMRole",
  ]

  eks_aws_auth_users = [
    "arn:aws:iam::1234567890123:user/MyIAMUSer"
  ]

  enable_ebs_csi_driver = true
  enable_aws_loadbalancer_controller = true
  install_karpenter = true

  default_tags = {
    Environment = "myenvironment"
    ManagedBy   = "Terraform"
    Product     = "Tower"
    CreatedBy   = "DevOps"
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.0.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_loadbalancer_controller_iam_policy"></a> [aws\_loadbalancer\_controller\_iam\_policy](#module\_aws\_loadbalancer\_controller\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | n/a |
| <a name="module_db"></a> [db](#module\_db) | terraform-aws-modules/rds/aws | n/a |
| <a name="module_db_sg"></a> [db\_sg](#module\_db\_sg) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_ebs_csi_driver_iam_policy"></a> [ebs\_csi\_driver\_iam\_policy](#module\_ebs\_csi\_driver\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 19.0 |
| <a name="module_memory_db"></a> [memory\_db](#module\_memory\_db) | terraform-aws-modules/memory-db/aws | n/a |
| <a name="module_redis_sg"></a> [redis\_sg](#module\_redis\_sg) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_seqera_iam_policy"></a> [seqera\_iam\_policy](#module\_seqera\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | n/a |
| <a name="module_seqera_irsa"></a> [seqera\_irsa](#module\_seqera\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.aws-ebs-csi-driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_node_template](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_provisioner](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_service_account_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [null_resource.ingress_crd](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.0.0/docs/data-sources/caller_identity) | data source |

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
| <a name="input_aws_loadbalancer_controller_iam_policy"></a> [aws\_loadbalancer\_controller\_iam\_policy](#input\_aws\_loadbalancer\_controller\_iam\_policy) | IAM policy for the AWS LoadBalancer Controller | `string` | `"{\n    \"Version\": \"2012-10-17\",\n    \"Statement\": [\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"iam:CreateServiceLinkedRole\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"iam:AWSServiceName\": \"elasticloadbalancing.amazonaws.com\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DescribeAccountAttributes\",\n                \"ec2:DescribeAddresses\",\n                \"ec2:DescribeAvailabilityZones\",\n                \"ec2:DescribeInternetGateways\",\n                \"ec2:DescribeVpcs\",\n                \"ec2:DescribeVpcPeeringConnections\",\n                \"ec2:DescribeSubnets\",\n                \"ec2:DescribeSecurityGroups\",\n                \"ec2:DescribeInstances\",\n                \"ec2:DescribeNetworkInterfaces\",\n                \"ec2:DescribeTags\",\n                \"ec2:GetCoipPoolUsage\",\n                \"ec2:DescribeCoipPools\",\n                \"elasticloadbalancing:DescribeLoadBalancers\",\n                \"elasticloadbalancing:DescribeLoadBalancerAttributes\",\n                \"elasticloadbalancing:DescribeListeners\",\n                \"elasticloadbalancing:DescribeListenerCertificates\",\n                \"elasticloadbalancing:DescribeSSLPolicies\",\n                \"elasticloadbalancing:DescribeRules\",\n                \"elasticloadbalancing:DescribeTargetGroups\",\n                \"elasticloadbalancing:DescribeTargetGroupAttributes\",\n                \"elasticloadbalancing:DescribeTargetHealth\",\n                \"elasticloadbalancing:DescribeTags\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"cognito-idp:DescribeUserPoolClient\",\n                \"acm:ListCertificates\",\n                \"acm:DescribeCertificate\",\n                \"iam:ListServerCertificates\",\n                \"iam:GetServerCertificate\",\n                \"waf-regional:GetWebACL\",\n                \"waf-regional:GetWebACLForResource\",\n                \"waf-regional:AssociateWebACL\",\n                \"waf-regional:DisassociateWebACL\",\n                \"wafv2:GetWebACL\",\n                \"wafv2:GetWebACLForResource\",\n                \"wafv2:AssociateWebACL\",\n                \"wafv2:DisassociateWebACL\",\n                \"shield:GetSubscriptionState\",\n                \"shield:DescribeProtection\",\n                \"shield:CreateProtection\",\n                \"shield:DeleteProtection\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:AuthorizeSecurityGroupIngress\",\n                \"ec2:RevokeSecurityGroupIngress\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateSecurityGroup\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateTags\"\n            ],\n            \"Resource\": \"arn:aws:ec2:*:*:security-group/*\",\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"ec2:CreateAction\": \"CreateSecurityGroup\"\n                },\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateTags\",\n                \"ec2:DeleteTags\"\n            ],\n            \"Resource\": \"arn:aws:ec2:*:*:security-group/*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"true\",\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:AuthorizeSecurityGroupIngress\",\n                \"ec2:RevokeSecurityGroupIngress\",\n                \"ec2:DeleteSecurityGroup\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:CreateLoadBalancer\",\n                \"elasticloadbalancing:CreateTargetGroup\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:CreateListener\",\n                \"elasticloadbalancing:DeleteListener\",\n                \"elasticloadbalancing:CreateRule\",\n                \"elasticloadbalancing:DeleteRule\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:AddTags\",\n                \"elasticloadbalancing:RemoveTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*\"\n            ],\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"true\",\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:AddTags\",\n                \"elasticloadbalancing:RemoveTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*\"\n            ]\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:ModifyLoadBalancerAttributes\",\n                \"elasticloadbalancing:SetIpAddressType\",\n                \"elasticloadbalancing:SetSecurityGroups\",\n                \"elasticloadbalancing:SetSubnets\",\n                \"elasticloadbalancing:DeleteLoadBalancer\",\n                \"elasticloadbalancing:ModifyTargetGroup\",\n                \"elasticloadbalancing:ModifyTargetGroupAttributes\",\n                \"elasticloadbalancing:DeleteTargetGroup\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"Null\": {\n                    \"aws:ResourceTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:AddTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*\",\n                \"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*\"\n            ],\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"elasticloadbalancing:CreateAction\": [\n                        \"CreateTargetGroup\",\n                        \"CreateLoadBalancer\"\n                    ]\n                },\n                \"Null\": {\n                    \"aws:RequestTag/elbv2.k8s.aws/cluster\": \"false\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:RegisterTargets\",\n                \"elasticloadbalancing:DeregisterTargets\"\n            ],\n            \"Resource\": \"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"elasticloadbalancing:SetWebAcl\",\n                \"elasticloadbalancing:ModifyListener\",\n                \"elasticloadbalancing:AddListenerCertificates\",\n                \"elasticloadbalancing:RemoveListenerCertificates\",\n                \"elasticloadbalancing:ModifyRule\"\n            ],\n            \"Resource\": \"*\"\n        }\n    ]\n}\n\n"` | no |
| <a name="input_aws_loadbalancer_controller_iam_policy_name"></a> [aws\_loadbalancer\_controller\_iam\_policy\_name](#input\_aws\_loadbalancer\_controller\_iam\_policy\_name) | The name of the IAM policy for the AWS LoadBalancer Controller | `string` | `"aws-loadbalancer-controller-iam-policy"` | no |
| <a name="input_aws_loadbalancer_controller_version"></a> [aws\_loadbalancer\_controller\_version](#input\_aws\_loadbalancer\_controller\_version) | The version of the AWS LoadBalancer Controller to deploy | `string` | `"1.6.0"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile used for authentication when interacting with AWS resources. | `string` | `"default"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The version of Kubernetes to use for the EKS cluster. | `string` | `"1.27"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Determines whether a database subnet group should be created. | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Determines whether a subnet route table should be created for the database subnets. | `bool` | `true` | no |
| <a name="input_create_elasticache_subnet_group"></a> [create\_elasticache\_subnet\_group](#input\_create\_elasticache\_subnet\_group) | Determines whether an Elasticache subnet group should be created. | `bool` | `false` | no |
| <a name="input_create_seqera_namespace"></a> [create\_seqera\_namespace](#input\_create\_seqera\_namespace) | Determines whether to create the Seqera namespace. | `bool` | `true` | no |
| <a name="input_create_seqera_service_account"></a> [create\_seqera\_service\_account](#input\_create\_seqera\_service\_account) | Determines whether to create the Seqera service account. | `bool` | `true` | no |
| <a name="input_database_identifier"></a> [database\_identifier](#input\_database\_identifier) | The identifier for the database. | `string` | `"seqera-db"` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | The allocated storage size for the database. | `number` | `10` | no |
| <a name="input_db_backup_window"></a> [db\_backup\_window](#input\_db\_backup\_window) | The backup window for the database. | `string` | `"03:00-06:00"` | no |
| <a name="input_db_create_monitoring_role"></a> [db\_create\_monitoring\_role](#input\_db\_create\_monitoring\_role) | Determines whether the monitoring role should be created. | `bool` | `false` | no |
| <a name="input_db_deletion_protection"></a> [db\_deletion\_protection](#input\_db\_deletion\_protection) | Determines whether deletion protection is enabled for the database. | `bool` | `false` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | The version of the database engine. | `string` | `"5.7"` | no |
| <a name="input_db_family"></a> [db\_family](#input\_db\_family) | The family of the database engine. | `string` | `"mysql5.7"` | no |
| <a name="input_db_iam_database_authentication_enabled"></a> [db\_iam\_database\_authentication\_enabled](#input\_db\_iam\_database\_authentication\_enabled) | Determines whether IAM database authentication is enabled for the database. | `bool` | `false` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | The instance class for the database. | `string` | `"db.r5.xlarge"` | no |
| <a name="input_db_maintenance_window"></a> [db\_maintenance\_window](#input\_db\_maintenance\_window) | The maintenance window for the database. | `string` | `"Mon:00:00-Mon:03:00"` | no |
| <a name="input_db_major_engine_version"></a> [db\_major\_engine\_version](#input\_db\_major\_engine\_version) | The major version of the database engine. | `string` | `"5.7"` | no |
| <a name="input_db_monitoring_interval"></a> [db\_monitoring\_interval](#input\_db\_monitoring\_interval) | The monitoring interval for the database. | `string` | `"0"` | no |
| <a name="input_db_monitoring_role_name"></a> [db\_monitoring\_role\_name](#input\_db\_monitoring\_role\_name) | The name of the IAM role used for database monitoring. | `string` | `"SeqeraRDSMonitoringRole"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database. | `string` | `"seqera"` | no |
| <a name="input_db_options"></a> [db\_options](#input\_db\_options) | The list of database options. | <pre>list(object({<br>    option_name = string<br>    option_settings = list(object({<br>      name  = string<br>      value = string<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "option_name": "MARIADB_AUDIT_PLUGIN",<br>    "option_settings": [<br>      {<br>        "name": "SERVER_AUDIT_EVENTS",<br>        "value": "CONNECT"<br>      },<br>      {<br>        "name": "SERVER_AUDIT_FILE_ROTATIONS",<br>        "value": "37"<br>      }<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_db_parameters"></a> [db\_parameters](#input\_db\_parameters) | The list of database parameters. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "character_set_client",<br>    "value": "utf8mb4"<br>  },<br>  {<br>    "name": "character_set_server",<br>    "value": "utf8mb4"<br>  }<br>]</pre> | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file. The password provided will not be used if `manage_master_user_password` is set to true. | `string` | `"my_db_password"` | no |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | The port for the database. | `string` | `"3306"` | no |
| <a name="input_db_security_group_name"></a> [db\_security\_group\_name](#input\_db\_security\_group\_name) | The name of the security group for the database. | `string` | `"seqera_db_security_group"` | no |
| <a name="input_db_skip_final_snapshot"></a> [db\_skip\_final\_snapshot](#input\_db\_skip\_final\_snapshot) | Determines whether a final snapshot should be created when the database is deleted. | `bool` | `true` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | The username for the database. | `string` | `"admin"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to be applied to the provisioned resources. | `map(string)` | <pre>{<br>  "ManagedBy": "Terraform",<br>  "Product": "Seqera Platform"<br>}</pre> | no |
| <a name="input_ebs_csi_driver_iam_policy"></a> [ebs\_csi\_driver\_iam\_policy](#input\_ebs\_csi\_driver\_iam\_policy) | IAM policy for the EBS CSI driver | `string` | `"{\n    \"Version\": \"2012-10-17\",\n    \"Statement\": [\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateSnapshot\",\n                \"ec2:AttachVolume\",\n                \"ec2:DetachVolume\",\n                \"ec2:ModifyVolume\",\n                \"ec2:DescribeAvailabilityZones\",\n                \"ec2:DescribeInstances\",\n                \"ec2:DescribeSnapshots\",\n                \"ec2:DescribeTags\",\n                \"ec2:DescribeVolumes\",\n                \"ec2:DescribeVolumesModifications\"\n            ],\n            \"Resource\": \"*\"\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:ec2:*:*:volume/*\",\n                \"arn:aws:ec2:*:*:snapshot/*\"\n            ],\n            \"Condition\": {\n                \"StringEquals\": {\n                    \"ec2:CreateAction\": [\n                        \"CreateVolume\",\n                        \"CreateSnapshot\"\n                    ]\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteTags\"\n            ],\n            \"Resource\": [\n                \"arn:aws:ec2:*:*:volume/*\",\n                \"arn:aws:ec2:*:*:snapshot/*\"\n            ]\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"aws:RequestTag/ebs.csi.aws.com/cluster\": \"true\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:CreateVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"aws:RequestTag/CSIVolumeName\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/ebs.csi.aws.com/cluster\": \"true\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/CSIVolumeName\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteVolume\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/kubernetes.io/created-for/pvc/name\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteSnapshot\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/CSIVolumeSnapshotName\": \"*\"\n                }\n            }\n        },\n        {\n            \"Effect\": \"Allow\",\n            \"Action\": [\n                \"ec2:DeleteSnapshot\"\n            ],\n            \"Resource\": \"*\",\n            \"Condition\": {\n                \"StringLike\": {\n                    \"ec2:ResourceTag/ebs.csi.aws.com/cluster\": \"true\"\n                }\n            }\n        }\n    ]\n}\n"` | no |
| <a name="input_ebs_csi_driver_iam_policy_name"></a> [ebs\_csi\_driver\_iam\_policy\_name](#input\_ebs\_csi\_driver\_iam\_policy\_name) | The name of the IAM policy for the EBS CSI driver. | `string` | `"ebs-csi-driver-iam-policy"` | no |
| <a name="input_ebs_csi_driver_version"></a> [ebs\_csi\_driver\_version](#input\_ebs\_csi\_driver\_version) | The version of the EBS CSI driver to deploy. | `string` | `"2.13.0"` | no |
| <a name="input_eks_aws_auth_roles"></a> [eks\_aws\_auth\_roles](#input\_eks\_aws\_auth\_roles) | List of roles ARNs to add to the aws-auth config map | `list(string)` | `[]` | no |
| <a name="input_eks_aws_auth_users"></a> [eks\_aws\_auth\_users](#input\_eks\_aws\_auth\_users) | List of users ARNs to add to the aws-auth config map | `list(string)` | `[]` | no |
| <a name="input_eks_cluster_addons"></a> [eks\_cluster\_addons](#input\_eks\_cluster\_addons) | Addons to be enabled for the EKS cluster. | <pre>map(object({<br>    most_recent = bool<br>  }))</pre> | <pre>{<br>  "coredns": {<br>    "most_recent": true<br>  },<br>  "kube-proxy": {<br>    "most_recent": true<br>  },<br>  "vpc-cni": {<br>    "most_recent": true<br>  }<br>}</pre> | no |
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | Determines whether the EKS cluster endpoint is publicly accessible. | `bool` | `true` | no |
| <a name="input_eks_enable_irsa"></a> [eks\_enable\_irsa](#input\_eks\_enable\_irsa) | Determines whether to create an OpenID Connect Provider for EKS to enable IRSA | `bool` | `true` | no |
| <a name="input_eks_manage_aws_auth_configmap"></a> [eks\_manage\_aws\_auth\_configmap](#input\_eks\_manage\_aws\_auth\_configmap) | Determines whether to manage the aws-auth ConfigMap. | `bool` | `true` | no |
| <a name="input_eks_managed_node_group_defaults_capacity_type"></a> [eks\_managed\_node\_group\_defaults\_capacity\_type](#input\_eks\_managed\_node\_group\_defaults\_capacity\_type) | The capacity type for the default managed node group. | `string` | `"ON_DEMAND"` | no |
| <a name="input_eks_managed_node_group_defaults_instance_types"></a> [eks\_managed\_node\_group\_defaults\_instance\_types](#input\_eks\_managed\_node\_group\_defaults\_instance\_types) | A list of EC2 instance types for the default managed node group. | `list(string)` | <pre>[<br>  "m5a.2xlarge"<br>]</pre> | no |
| <a name="input_eks_managed_node_group_desired_size"></a> [eks\_managed\_node\_group\_desired\_size](#input\_eks\_managed\_node\_group\_desired\_size) | The desired size of the EKS managed node group. | `number` | `2` | no |
| <a name="input_eks_managed_node_group_max_size"></a> [eks\_managed\_node\_group\_max\_size](#input\_eks\_managed\_node\_group\_max\_size) | The maximum size of the EKS managed node group. | `number` | `4` | no |
| <a name="input_eks_managed_node_group_min_size"></a> [eks\_managed\_node\_group\_min\_size](#input\_eks\_managed\_node\_group\_min\_size) | The minimum size of the EKS managed node group. | `number` | `2` | no |
| <a name="input_enable_aws_loadbalancer_controller"></a> [enable\_aws\_loadbalancer\_controller](#input\_enable\_aws\_loadbalancer\_controller) | Determines whether the AWS LoadBalancer Controller should be deployed. | `bool` | `true` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Determines whether instances in the VPC receive DNS hostnames. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Determines whether DNS resolution is supported for the VPC. | `bool` | `true` | no |
| <a name="input_enable_ebs_csi_driver"></a> [enable\_ebs\_csi\_driver](#input\_enable\_ebs\_csi\_driver) | Determines whether the EBS CSI driver should be deployed. | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Determines whether NAT gateways should be provisioned. | `bool` | `true` | no |
| <a name="input_enable_vpn_gateway"></a> [enable\_vpn\_gateway](#input\_enable\_vpn\_gateway) | Determines whether a VPN gateway should be provisioned. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment in which the infrastructure is being deployed. | `string` | `""` | no |
| <a name="input_install_karpenter"></a> [install\_karpenter](#input\_install\_karpenter) | Determines whether to install Karpenter | `bool` | `false` | no |
| <a name="input_karpenter_version"></a> [karpenter\_version](#input\_karpenter\_version) | Karpenter version | `string` | `"v0.30.0-rc.0"` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Determines whether each Availability Zone should have a dedicated NAT gateway. | `bool` | `true` | no |
| <a name="input_redis_auto_minor_version_upgrade"></a> [redis\_auto\_minor\_version\_upgrade](#input\_redis\_auto\_minor\_version\_upgrade) | Determines whether automatic minor version upgrades are enabled for Redis. | `bool` | `false` | no |
| <a name="input_redis_cluster_name"></a> [redis\_cluster\_name](#input\_redis\_cluster\_name) | The name of the Redis cluster. | `string` | `"seqera-redis"` | no |
| <a name="input_redis_create_subnet_group"></a> [redis\_create\_subnet\_group](#input\_redis\_create\_subnet\_group) | Determines whether to create a Redis subnet group. | `bool` | `true` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | The version of the Redis engine. | `string` | `"6.2"` | no |
| <a name="input_redis_maintenance_window"></a> [redis\_maintenance\_window](#input\_redis\_maintenance\_window) | The maintenance window for the Redis cluster. | `string` | `"sun:23:00-mon:01:30"` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | The Redis node type. | `string` | `"db.t4g.small"` | no |
| <a name="input_redis_num_replicas_per_shard"></a> [redis\_num\_replicas\_per\_shard](#input\_redis\_num\_replicas\_per\_shard) | The number of replicas per shard in the Redis cluster. | `number` | `2` | no |
| <a name="input_redis_num_shards"></a> [redis\_num\_shards](#input\_redis\_num\_shards) | The number of shards in the Redis cluster. | `number` | `2` | no |
| <a name="input_redis_parameter_group_description"></a> [redis\_parameter\_group\_description](#input\_redis\_parameter\_group\_description) | The description of the Redis parameter group. | `string` | `"Redis MemoryDB parameter group"` | no |
| <a name="input_redis_parameter_group_family"></a> [redis\_parameter\_group\_family](#input\_redis\_parameter\_group\_family) | The family of the Redis parameter group. | `string` | `"memorydb_redis6"` | no |
| <a name="input_redis_parameter_group_name"></a> [redis\_parameter\_group\_name](#input\_redis\_parameter\_group\_name) | The name of the Redis parameter group. | `string` | `"redis-param-group"` | no |
| <a name="input_redis_parameter_group_parameters"></a> [redis\_parameter\_group\_parameters](#input\_redis\_parameter\_group\_parameters) | A list of Redis parameter configurations. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "activedefrag",<br>    "value": "yes"<br>  }<br>]</pre> | no |
| <a name="input_redis_parameter_group_tags"></a> [redis\_parameter\_group\_tags](#input\_redis\_parameter\_group\_tags) | Tags to be applied to the Redis parameter group. | `map(string)` | <pre>{<br>  "ParameterGroup": "custom"<br>}</pre> | no |
| <a name="input_redis_security_group_name"></a> [redis\_security\_group\_name](#input\_redis\_security\_group\_name) | The name of the security group for Redis. | `string` | `"seqera_redis_security_group"` | no |
| <a name="input_redis_snapshot_retention_limit"></a> [redis\_snapshot\_retention\_limit](#input\_redis\_snapshot\_retention\_limit) | The number of days to retain Redis snapshots. | `number` | `7` | no |
| <a name="input_redis_snapshot_window"></a> [redis\_snapshot\_window](#input\_redis\_snapshot\_window) | The window during which Redis snapshots are taken. | `string` | `"05:00-09:00"` | no |
| <a name="input_redis_subnet_group_description"></a> [redis\_subnet\_group\_description](#input\_redis\_subnet\_group\_description) | The description of the Redis subnet group. | `string` | `"Seqera MemoryDB subnet group"` | no |
| <a name="input_redis_subnet_group_name"></a> [redis\_subnet\_group\_name](#input\_redis\_subnet\_group\_name) | The name of the Redis subnet group. | `string` | `"seqera-redis-subnetgroup"` | no |
| <a name="input_redis_tls_enabled"></a> [redis\_tls\_enabled](#input\_redis\_tls\_enabled) | Determines whether TLS (Transport Layer Security) is enabled for Redis. | `bool` | `true` | no |
| <a name="input_redis_users"></a> [redis\_users](#input\_redis\_users) | A map of Redis user configurations. | <pre>map(object({<br>    user_name     = string<br>    access_string = string<br>    passwords     = list(string)<br>    tags          = map(string)<br>  }))</pre> | <pre>{<br>  "admin": {<br>    "access_string": "on ~* &* +@all",<br>    "passwords": [<br>      "YouShouldPickAStrongSecurePassword987!"<br>    ],<br>    "tags": {<br>      "User": "admin"<br>    },<br>    "user_name": "seqera-admin-user"<br>  },<br>  "readonly": {<br>    "access_string": "on ~* &* -@all +@read",<br>    "passwords": [<br>      "YouShouldPickAStrongSecurePassword123!"<br>    ],<br>    "tags": {<br>      "User": "readonly"<br>    },<br>    "user_name": "seqera-readonly-user"<br>  }<br>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region in which the resources will be provisioned. | `string` | `"eu-west-1"` | no |
| <a name="input_seqera_irsa_iam_policy_name"></a> [seqera\_irsa\_iam\_policy\_name](#input\_seqera\_irsa\_iam\_policy\_name) | The name of the IAM policy for IRSA. | `string` | `"seqera-irsa-iam-policy"` | no |
| <a name="input_seqera_irsa_role_name"></a> [seqera\_irsa\_role\_name](#input\_seqera\_irsa\_role\_name) | The name of the IAM role for IRSA. | `string` | `"seqera-irsa-role"` | no |
| <a name="input_seqera_namespace_name"></a> [seqera\_namespace\_name](#input\_seqera\_namespace\_name) | The name of the namespace used to deploy Seqera platform manifests. | `string` | `"seqera-platform"` | no |
| <a name="input_seqera_platform_service_account_iam_policy"></a> [seqera\_platform\_service\_account\_iam\_policy](#input\_seqera\_platform\_service\_account\_iam\_policy) | IAM policy for the Seqera service account | `string` | `"{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n      {\n          \"Sid\": \"TowerForge0\",\n          \"Effect\": \"Allow\",\n          \"Action\": [\n              \"ssm:GetParameters\",\n              \"iam:CreateInstanceProfile\",\n              \"iam:DeleteInstanceProfile\",\n              \"iam:GetRole\",\n              \"iam:RemoveRoleFromInstanceProfile\",\n              \"iam:CreateRole\",\n              \"iam:DeleteRole\",\n              \"iam:AttachRolePolicy\",\n              \"iam:PutRolePolicy\",\n              \"iam:AddRoleToInstanceProfile\",\n              \"iam:PassRole\",\n              \"iam:DetachRolePolicy\",\n              \"iam:ListAttachedRolePolicies\",\n              \"iam:DeleteRolePolicy\",\n              \"iam:ListRolePolicies\",\n              \"iam:TagRole\",\n              \"iam:TagInstanceProfile\",\n              \"batch:CreateComputeEnvironment\",\n              \"batch:DescribeComputeEnvironments\",\n              \"batch:CreateJobQueue\",\n              \"batch:DescribeJobQueues\",\n              \"batch:UpdateComputeEnvironment\",\n              \"batch:DeleteComputeEnvironment\",\n              \"batch:UpdateJobQueue\",\n              \"batch:DeleteJobQueue\",\n              \"batch:TagResource\",\n              \"fsx:DeleteFileSystem\",\n              \"fsx:DescribeFileSystems\",\n              \"fsx:CreateFileSystem\",\n              \"fsx:TagResource\",\n              \"ec2:DescribeSecurityGroups\",\n              \"ec2:DescribeAccountAttributes\",\n              \"ec2:DescribeSubnets\",\n              \"ec2:DescribeLaunchTemplates\",\n              \"ec2:DescribeLaunchTemplateVersions\", \n              \"ec2:CreateLaunchTemplate\",\n              \"ec2:DeleteLaunchTemplate\",\n              \"ec2:DescribeKeyPairs\",\n              \"ec2:DescribeVpcs\",\n              \"ec2:DescribeInstanceTypeOfferings\",\n              \"ec2:GetEbsEncryptionByDefault\",\n              \"elasticfilesystem:DescribeMountTargets\",\n              \"elasticfilesystem:CreateMountTarget\",\n              \"elasticfilesystem:CreateFileSystem\",\n              \"elasticfilesystem:DescribeFileSystems\",\n              \"elasticfilesystem:DeleteMountTarget\",\n              \"elasticfilesystem:DeleteFileSystem\",\n              \"elasticfilesystem:UpdateFileSystem\",\n              \"elasticfilesystem:PutLifecycleConfiguration\",\n              \"elasticfilesystem:TagResource\"\n          ],\n          \"Resource\": \"*\"\n      },\n      {\n          \"Sid\": \"TowerLaunch0\",\n          \"Effect\": \"Allow\",\n          \"Action\": [\n              \"s3:Get*\",\n              \"s3:List*\",\n              \"batch:DescribeJobQueues\",\n              \"batch:CancelJob\",\n              \"batch:SubmitJob\",\n              \"batch:ListJobs\",\n              \"batch:DescribeComputeEnvironments\",\n              \"batch:TerminateJob\",\n              \"batch:DescribeJobs\",\n              \"batch:RegisterJobDefinition\",\n              \"batch:DescribeJobDefinitions\",\n              \"ecs:DescribeTasks\",\n              \"ec2:DescribeInstances\",\n              \"ec2:DescribeInstanceTypes\",\n              \"ec2:DescribeInstanceAttribute\",\n              \"ecs:DescribeContainerInstances\",\n              \"ec2:DescribeInstanceStatus\",\n              \"ec2:DescribeImages\",\n              \"logs:Describe*\",\n              \"logs:Get*\",\n              \"logs:List*\",\n              \"logs:StartQuery\",\n              \"logs:StopQuery\",\n              \"logs:TestMetricFilter\",\n              \"logs:FilterLogEvents\"\n          ],\n          \"Resource\": \"*\"\n      }\n  ]\n}\n"` | no |
| <a name="input_seqera_service_account_name"></a> [seqera\_service\_account\_name](#input\_seqera\_service\_account\_name) | Name for the Seqera platform service account | `string` | `"seqera-sa"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_url"></a> [database\_url](#output\_database\_url) | Database URL |
| <a name="output_redis_url"></a> [redis\_url](#output\_redis\_url) | Redis URL |
| <a name="output_seqera_irsa_role_name"></a> [seqera\_irsa\_role\_name](#output\_seqera\_irsa\_role\_name) | Seqera IRSA Role Name |
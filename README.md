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
module "terraform-seqera-module" {
  source  = "github.com/seqeralabs/terraform-seqera-module"
  profile = "development"
  region  = "eu-west-2"

  ## VPC
  vpc_name = "terraform-seqera-module"
  vpc_cidr = "10.0.0.0/16"

  azs                 = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets    = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]
  elasticache_subnets = ["10.0.107.0/24", "10.0.108.0/24", "10.0.109.0/24"]
  intra_subnets       = ["10.0.110.0/24", "10.0.111.0/24", "10.0.112.0/24"]

  ## EKS
  cluster_name    = "tower"
  cluster_version = "1.27"
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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_db"></a> [db](#module\_db) | terraform-aws-modules/rds/aws | n/a |
| <a name="module_db_sg"></a> [db\_sg](#module\_db\_sg) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 19.0 |
| <a name="module_memory_db"></a> [memory\_db](#module\_memory\_db) | terraform-aws-modules/memory-db/aws | n/a |
| <a name="module_redis_sg"></a> [redis\_sg](#module\_redis\_sg) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | A list of Availability Zones in the selected region. | `list(string)` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_database_subnets"></a> [database\_subnets](#input\_database\_subnets) | A list of subnet IDs for database subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_elasticache_subnets"></a> [elasticache\_subnets](#input\_elasticache\_subnets) | A list of subnet IDs for Elasticache subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_intra_subnets"></a> [intra\_subnets](#input\_intra\_subnets) | A list of subnet IDs for intra subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of subnet IDs for private subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | The AWS profile used for authentication when interacting with AWS resources. | `string` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of subnet IDs for public subnets within the VPC. | `list(string)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC. | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the Virtual Private Cloud (VPC) to be created. | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | The version of Kubernetes to use for the EKS cluster. | `string` | `"1.27"` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Determines whether a database subnet group should be created. | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Determines whether a subnet route table should be created for the database subnets. | `bool` | `true` | no |
| <a name="input_create_elasticache_subnet_group"></a> [create\_elasticache\_subnet\_group](#input\_create\_elasticache\_subnet\_group) | Determines whether an Elasticache subnet group should be created. | `bool` | `false` | no |
| <a name="input_database_identifier"></a> [database\_identifier](#input\_database\_identifier) | The identifier for the database. | `string` | `"tower"` | no |
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
| <a name="input_db_monitoring_role_name"></a> [db\_monitoring\_role\_name](#input\_db\_monitoring\_role\_name) | The name of the IAM role used for database monitoring. | `string` | `"TowerRDSMonitoringRole"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database. | `string` | `"tower"` | no |
| <a name="input_db_options"></a> [db\_options](#input\_db\_options) | The list of database options. | <pre>list(object({<br>    option_name = string<br>    option_settings = list(object({<br>      name  = string<br>      value = string<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "option_name": "MARIADB_AUDIT_PLUGIN",<br>    "option_settings": [<br>      {<br>        "name": "SERVER_AUDIT_EVENTS",<br>        "value": "CONNECT"<br>      },<br>      {<br>        "name": "SERVER_AUDIT_FILE_ROTATIONS",<br>        "value": "37"<br>      }<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_db_parameters"></a> [db\_parameters](#input\_db\_parameters) | The list of database parameters. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "character_set_client",<br>    "value": "utf8mb4"<br>  },<br>  {<br>    "name": "character_set_server",<br>    "value": "utf8mb4"<br>  }<br>]</pre> | no |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | The port for the database. | `string` | `"3306"` | no |
| <a name="input_db_security_group_name"></a> [db\_security\_group\_name](#input\_db\_security\_group\_name) | The name of the security group for the database. | `string` | `"tower_db_security_group"` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | The username for the database. | `string` | `"tower"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to be applied to the provisioned resources. | `map(string)` | <pre>{<br>  "Environment": "Development",<br>  "ManagedBy": "Terraform",<br>  "Product": "Tower"<br>}</pre> | no |
| <a name="input_eks_cluster_addons"></a> [eks\_cluster\_addons](#input\_eks\_cluster\_addons) | Addons to be enabled for the EKS cluster. | <pre>map(object({<br>    most_recent = bool<br>  }))</pre> | <pre>{<br>  "coredns": {<br>    "most_recent": true<br>  },<br>  "kube-proxy": {<br>    "most_recent": true<br>  },<br>  "vpc-cni": {<br>    "most_recent": true<br>  }<br>}</pre> | no |
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | Determines whether the EKS cluster endpoint is publicly accessible. | `bool` | `true` | no |
| <a name="input_eks_managed_node_group_defaults_capacity_type"></a> [eks\_managed\_node\_group\_defaults\_capacity\_type](#input\_eks\_managed\_node\_group\_defaults\_capacity\_type) | The capacity type for the default managed node group. | `string` | `"SPOT"` | no |
| <a name="input_eks_managed_node_group_defaults_instance_types"></a> [eks\_managed\_node\_group\_defaults\_instance\_types](#input\_eks\_managed\_node\_group\_defaults\_instance\_types) | A list of EC2 instance types for the default managed node group. | `list(string)` | <pre>[<br>  "m5a.2xlarge"<br>]</pre> | no |
| <a name="input_eks_managed_node_group_desired_size"></a> [eks\_managed\_node\_group\_desired\_size](#input\_eks\_managed\_node\_group\_desired\_size) | The desired size of the EKS managed node group. | `number` | `1` | no |
| <a name="input_eks_managed_node_group_max_size"></a> [eks\_managed\_node\_group\_max\_size](#input\_eks\_managed\_node\_group\_max\_size) | The maximum size of the EKS managed node group. | `number` | `5` | no |
| <a name="input_eks_managed_node_group_min_size"></a> [eks\_managed\_node\_group\_min\_size](#input\_eks\_managed\_node\_group\_min\_size) | The minimum size of the EKS managed node group. | `number` | `1` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Determines whether instances in the VPC receive DNS hostnames. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Determines whether DNS resolution is supported for the VPC. | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Determines whether NAT gateways should be provisioned. | `bool` | `true` | no |
| <a name="input_enable_vpn_gateway"></a> [enable\_vpn\_gateway](#input\_enable\_vpn\_gateway) | Determines whether a VPN gateway should be provisioned. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment in which the infrastructure is being deployed. | `string` | `""` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Determines whether each Availability Zone should have a dedicated NAT gateway. | `bool` | `true` | no |
| <a name="input_redis_auto_minor_version_upgrade"></a> [redis\_auto\_minor\_version\_upgrade](#input\_redis\_auto\_minor\_version\_upgrade) | Determines whether automatic minor version upgrades are enabled for Redis. | `bool` | `false` | no |
| <a name="input_redis_cluster_name"></a> [redis\_cluster\_name](#input\_redis\_cluster\_name) | The name of the Redis cluster. | `string` | `"tower"` | no |
| <a name="input_redis_create_subnet_group"></a> [redis\_create\_subnet\_group](#input\_redis\_create\_subnet\_group) | Determines whether to create a Redis subnet group. | `bool` | `true` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | The version of the Redis engine. | `string` | `"6.2"` | no |
| <a name="input_redis_maintenance_window"></a> [redis\_maintenance\_window](#input\_redis\_maintenance\_window) | The maintenance window for the Redis cluster. | `string` | `"sun:23:00-mon:01:30"` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | The Redis node type. | `string` | `"db.t4g.small"` | no |
| <a name="input_redis_num_replicas_per_shard"></a> [redis\_num\_replicas\_per\_shard](#input\_redis\_num\_replicas\_per\_shard) | The number of replicas per shard in the Redis cluster. | `number` | `2` | no |
| <a name="input_redis_num_shards"></a> [redis\_num\_shards](#input\_redis\_num\_shards) | The number of shards in the Redis cluster. | `number` | `2` | no |
| <a name="input_redis_parameter_group_description"></a> [redis\_parameter\_group\_description](#input\_redis\_parameter\_group\_description) | The description of the Redis parameter group. | `string` | `"Tower MemoryDB parameter group"` | no |
| <a name="input_redis_parameter_group_family"></a> [redis\_parameter\_group\_family](#input\_redis\_parameter\_group\_family) | The family of the Redis parameter group. | `string` | `"memorydb_redis6"` | no |
| <a name="input_redis_parameter_group_name"></a> [redis\_parameter\_group\_name](#input\_redis\_parameter\_group\_name) | The name of the Redis parameter group. | `string` | `"tower-param-group"` | no |
| <a name="input_redis_parameter_group_parameters"></a> [redis\_parameter\_group\_parameters](#input\_redis\_parameter\_group\_parameters) | A list of Redis parameter configurations. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "activedefrag",<br>    "value": "yes"<br>  }<br>]</pre> | no |
| <a name="input_redis_parameter_group_tags"></a> [redis\_parameter\_group\_tags](#input\_redis\_parameter\_group\_tags) | Tags to be applied to the Redis parameter group. | `map(string)` | <pre>{<br>  "ParameterGroup": "custom"<br>}</pre> | no |
| <a name="input_redis_security_group_name"></a> [redis\_security\_group\_name](#input\_redis\_security\_group\_name) | The name of the security group for Redis. | `string` | `"tower_redis_security_group"` | no |
| <a name="input_redis_snapshot_retention_limit"></a> [redis\_snapshot\_retention\_limit](#input\_redis\_snapshot\_retention\_limit) | The number of days to retain Redis snapshots. | `number` | `7` | no |
| <a name="input_redis_snapshot_window"></a> [redis\_snapshot\_window](#input\_redis\_snapshot\_window) | The window during which Redis snapshots are taken. | `string` | `"05:00-09:00"` | no |
| <a name="input_redis_subnet_group_description"></a> [redis\_subnet\_group\_description](#input\_redis\_subnet\_group\_description) | The description of the Redis subnet group. | `string` | `"Tower MemoryDB subnet group"` | no |
| <a name="input_redis_subnet_group_name"></a> [redis\_subnet\_group\_name](#input\_redis\_subnet\_group\_name) | The name of the Redis subnet group. | `string` | `"tower-redis-subnetgroup"` | no |
| <a name="input_redis_tls_enabled"></a> [redis\_tls\_enabled](#input\_redis\_tls\_enabled) | Determines whether TLS (Transport Layer Security) is enabled for Redis. | `bool` | `true` | no |
| <a name="input_redis_users"></a> [redis\_users](#input\_redis\_users) | A map of Redis user configurations. | <pre>map(object({<br>    user_name     = string<br>    access_string = string<br>    passwords     = list(string)<br>    tags          = map(string)<br>  }))</pre> | <pre>{<br>  "admin": {<br>    "access_string": "on ~* &* +@all",<br>    "passwords": [<br>      "YouShouldPickAStrongSecurePassword987!"<br>    ],<br>    "tags": {<br>      "User": "admin"<br>    },<br>    "user_name": "admin-user"<br>  },<br>  "readonly": {<br>    "access_string": "on ~* &* -@all +@read",<br>    "passwords": [<br>      "YouShouldPickAStrongSecurePassword123!"<br>    ],<br>    "tags": {<br>      "User": "readonly"<br>    },<br>    "user_name": "readonly-user"<br>  }<br>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region in which the resources will be provisioned. | `string` | `"eu-west-2"` | no |

## Outputs

No outputs.
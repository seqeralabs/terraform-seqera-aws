## Environment
variable "environment" {
  type        = string
  default     = ""
  description = "The environment in which the infrastructure is being deployed."
}

## Region
variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "The AWS region in which the resources will be provisioned."
}

## Tags
variable "default_tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
    Product   = "Seqera Platform"
  }
  description = "Default tags to be applied to the provisioned resources."
}

## AWS Profile
variable "aws_profile" {
  type        = string
  default     = "default"
  description = "The AWS profile used for authentication when interacting with AWS resources."
}

## VPC Name
variable "vpc_name" {
  type        = string
  description = "The name of the Virtual Private Cloud (VPC) to be created."
}

## VPC CIDR
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC."
}

## AWS LoadBalancer Controller
variable "enable_aws_loadbalancer_controller" {
  type        = bool
  default     = true
  description = "Determines whether the AWS LoadBalancer Controller should be deployed."
}

## Cluster Endpoint Public Access
variable "eks_cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Determines whether the EKS cluster endpoint is publicly accessible."
}

## EKS Cluster Addons
variable "eks_cluster_addons" {
  type = map(object({
    most_recent = bool
  }))
  default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  description = "Addons to be enabled for the EKS cluster."
}

## EKS Managed Node Group - Minimum Size
variable "eks_managed_node_group_min_size" {
  type        = number
  default     = 2
  description = "The minimum size of the EKS managed node group."
}

variable "eks_manage_aws_auth_configmap" {
  type        = bool
  default     = true
  description = "Determines whether to manage the aws-auth ConfigMap."
}

variable "eks_aws_auth_roles" {
  type        = list(string)
  default     = []
  description = "List of roles ARNs to add to the aws-auth config map"
}

variable "eks_aws_auth_users" {
  type        = list(string)
  default     = []
  description = "List of users ARNs to add to the aws-auth config map"
}

variable "enable_aws_cluster_autoscaler" {
  type        = bool
  default     = true
  description = "Determines whether the AWS Cluster Autoscaler should be deployed."
}

variable "aws_cluster_autoscaler_version" {
  type        = string
  default     = "9.29.3"
  description = "The version of the AWS Cluster Autoscaler to deploy."
}

variable "aws_cluster_autoscaler_iam_policy_name" {
  type        = string
  default     = "aws-cluster-autoscaler-iam-policy"
  description = "The name of the IAM policy for the AWS Cluster Autoscaler."
}

variable "aws_cluster_autoscaler_iam_policy" {
  type        = string
  description = "IAM policy for the AWS Cluster Autoscaler"
  default     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeImages",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

variable "enable_aws_efs_csi_driver" {
  type        = bool
  default     = true
  description = "Determines whether the AWS EFS CSI driver should be deployed."
}

variable "aws_efs_csi_driver_security_group_name" {
  type        = string
  default     = "aws-efs-csi-driver-sg"
  description = "The name of the security group for the AWS EFS CSI driver."
}

variable "aws_efs_csi_driver_security_group_ingress_rule_name" {
  type        = string
  default     = "nfs-tcp"
  description = "The name of the security group ingress rule for the AWS EFS CSI driver."
}

variable "aws_efs_csi_driver_version" {
  type        = string
  default     = "2.4.9"
  description = "The version of the AWS EFS CSI driver to deploy."
}

variable "aws_efs_csi_driver_iam_policy_name" {
  type        = string
  default     = "aws-efs-csi-driver-iam-policy"
  description = "The name of the IAM policy for the AWS EFS CSI driver."
}

variable "aws_efs_csi_driver_creation_token" {
  type        = string
  default     = "seqera-efs-csi-driver"
  description = "The creation token for the EFS file system."
}

variable "aws_efs_csi_driver_performance_mode" {
  type        = string
  default     = "generalPurpose"
  description = "The performance mode of the EFS file system."
}

variable "aws_efs_csi_driver_backup_policy_status" {
  type        = string
  default     = "ENABLED"
  description = "The backup policy status of the EFS file system."
}

variable "aws_efs_csi_driver_storage_class_name" {
  type        = string
  default     = "efs-sc"
  description = "The name of the storage class for the EFS file system."
}

variable "aws_efs_csi_driver_storage_class_reclaim_policy" {
  type        = string
  default     = "Retain"
  description = "The reclaim policy for the EFS file system."
}

variable "aws_efs_csi_driver_storage_class_parameters" {
  type = map(string)
  default = {
    provisioningMode = "efs-ap"
    directoryPerms   = "700"
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
    basePath         = "/dynamic_provisioning"
  }
  description = "The parameters for the storage class for the EFS file system."
}

variable "aws_efs_csi_driver_storage_class_storage_provisioner" {
  type        = string
  default     = "efs.csi.aws.com"
  description = "The storage provisioner for the EFS file system."
}

variable "aws_efs_csi_driver_iam_policy" {
  type        = string
  description = "IAM policy for the AWS EFS CSI driver"
  default     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:CreateAccessPoint"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:TagResource"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "elasticfilesystem:DeleteAccessPoint",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOF
}

variable "aws_loadbalancer_controller_iam_policy_name" {
  type        = string
  default     = "aws-loadbalancer-controller-iam-policy"
  description = "The name of the IAM policy for the AWS LoadBalancer Controller"
}

variable "aws_loadbalancer_controller_version" {
  type        = string
  default     = "1.6.0"
  description = "The version of the AWS LoadBalancer Controller to deploy"
}

variable "aws_loadbalancer_controller_iam_policy" {
  type        = string
  default     = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetCoipPoolUsage",
                "ec2:DescribeCoipPools",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticloadbalancing:CreateAction": [
                        "CreateTargetGroup",
                        "CreateLoadBalancer"
                    ]
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}

EOF
  description = "IAM policy for the AWS LoadBalancer Controller"
}

## Seqera Service Account IRSA IAM Policy
variable "seqera_platform_service_account_iam_policy" {
  type        = string
  description = "IAM policy for the Seqera service account"
  default     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "TowerForge0",
          "Effect": "Allow",
          "Action": [
              "ssm:GetParameters",
              "iam:CreateInstanceProfile",
              "iam:DeleteInstanceProfile",
              "iam:GetRole",
              "iam:RemoveRoleFromInstanceProfile",
              "iam:CreateRole",
              "iam:DeleteRole",
              "iam:AttachRolePolicy",
              "iam:PutRolePolicy",
              "iam:AddRoleToInstanceProfile",
              "iam:PassRole",
              "iam:DetachRolePolicy",
              "iam:ListAttachedRolePolicies",
              "iam:DeleteRolePolicy",
              "iam:ListRolePolicies",
              "iam:TagRole",
              "iam:TagInstanceProfile",
              "batch:CreateComputeEnvironment",
              "batch:DescribeComputeEnvironments",
              "batch:CreateJobQueue",
              "batch:DescribeJobQueues",
              "batch:UpdateComputeEnvironment",
              "batch:DeleteComputeEnvironment",
              "batch:UpdateJobQueue",
              "batch:DeleteJobQueue",
              "batch:TagResource",
              "fsx:DeleteFileSystem",
              "fsx:DescribeFileSystems",
              "fsx:CreateFileSystem",
              "fsx:TagResource",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeSubnets",
              "ec2:DescribeLaunchTemplates",
              "ec2:DescribeLaunchTemplateVersions", 
              "ec2:CreateLaunchTemplate",
              "ec2:DeleteLaunchTemplate",
              "ec2:DescribeKeyPairs",
              "ec2:DescribeVpcs",
              "ec2:DescribeInstanceTypeOfferings",
              "ec2:GetEbsEncryptionByDefault",
              "elasticfilesystem:DescribeMountTargets",
              "elasticfilesystem:CreateMountTarget",
              "elasticfilesystem:CreateFileSystem",
              "elasticfilesystem:DescribeFileSystems",
              "elasticfilesystem:DeleteMountTarget",
              "elasticfilesystem:DeleteFileSystem",
              "elasticfilesystem:UpdateFileSystem",
              "elasticfilesystem:PutLifecycleConfiguration",
              "elasticfilesystem:TagResource"
          ],
          "Resource": "*"
      },
      {
          "Sid": "TowerLaunch0",
          "Effect": "Allow",
          "Action": [
              "s3:Get*",
              "s3:List*",
              "batch:DescribeJobQueues",
              "batch:CancelJob",
              "batch:SubmitJob",
              "batch:ListJobs",
              "batch:DescribeComputeEnvironments",
              "batch:TerminateJob",
              "batch:DescribeJobs",
              "batch:RegisterJobDefinition",
              "batch:DescribeJobDefinitions",
              "ecs:DescribeTasks",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeInstanceAttribute",
              "ecs:DescribeContainerInstances",
              "ec2:DescribeInstanceStatus",
              "ec2:DescribeImages",
              "logs:Describe*",
              "logs:Get*",
              "logs:List*",
              "logs:StartQuery",
              "logs:StopQuery",
              "logs:TestMetricFilter",
              "logs:FilterLogEvents"
          ],
          "Resource": "*"
      }
  ]
}
EOF 
}

## Seqera Namespace Name
variable "seqera_namespace_name" {
  type        = string
  default     = "seqera-platform"
  description = "The name of the namespace used to deploy Seqera platform manifests."
}

variable "create_seqera_namespace" {
  type        = bool
  default     = true
  description = "Determines whether to create the Seqera namespace."
}

variable "create_seqera_service_account" {
  type        = bool
  default     = true
  description = "Determines whether to create the Seqera service account."
}

## Seqera Service Account Name
variable "seqera_service_account_name" {
  type        = string
  description = "Name for the Seqera platform service account"
  default     = "seqera-sa"
}

## EKS Enable IRSA
variable "eks_enable_irsa" {
  type        = bool
  default     = true
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
}

## EKS Managed Node Group - Maximum Size
variable "eks_managed_node_group_max_size" {
  type        = number
  default     = 4
  description = "The maximum size of the EKS managed node group."
}

## EKS Managed Node Group - Desired Size
variable "eks_managed_node_group_desired_size" {
  type        = number
  default     = 2
  description = "The desired size of the EKS managed node group."
}

## VPC Subnets
variable "intra_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for intra subnets within the VPC."
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for public subnets within the VPC."
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for private subnets within the VPC."
}

variable "database_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for database subnets within the VPC."
}

variable "elasticache_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for Elasticache subnets within the VPC."
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "Determines whether instances in the VPC receive DNS hostnames."
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "Determines whether DNS resolution is supported for the VPC."
}

variable "create_database_subnet_group" {
  type        = bool
  default     = true
  description = "Determines whether a database subnet group should be created."
}

variable "create_elasticache_subnet_group" {
  type        = bool
  default     = false
  description = "Determines whether an Elasticache subnet group should be created."
}

variable "create_database_subnet_route_table" {
  type        = bool
  default     = true
  description = "Determines whether a subnet route table should be created for the database subnets."
}

variable "one_nat_gateway_per_az" {
  type        = bool
  default     = true
  description = "Determines whether each Availability Zone should have a dedicated NAT gateway."
}

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Determines whether NAT gateways should be provisioned."
}

variable "enable_vpn_gateway" {
  type        = bool
  default     = false
  description = "Determines whether a VPN gateway should be provisioned."
}

## Availability Zones
variable "azs" {
  type        = list(string)
  description = "A list of Availability Zones in the selected region."
}

## EKS
variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
}

variable "cluster_version" {
  type        = string
  default     = "1.27"
  description = "The version of Kubernetes to use for the EKS cluster."
}

variable "eks_managed_node_group_defaults_instance_types" {
  type        = list(string)
  default     = ["m5a.2xlarge"]
  description = "A list of EC2 instance types for the default managed node group."
}

variable "eks_managed_node_group_defaults_capacity_type" {
  type        = string
  default     = "ON_DEMAND"
  description = "The capacity type for the default managed node group."
}

variable "enable_ebs_csi_driver" {
  type        = bool
  default     = true
  description = "Determines whether the EBS CSI driver should be deployed."
}

variable "ebs_csi_driver_version" {
  type        = string
  default     = "2.13.0"
  description = "The version of the EBS CSI driver to deploy."
}

variable "ebs_csi_driver_iam_policy_name" {
  type        = string
  default     = "ebs-csi-driver-iam-policy"
  description = "The name of the IAM policy for the EBS CSI driver."
}

variable "ebs_csi_driver_iam_policy" {
  type        = string
  description = "IAM policy for the EBS CSI driver"
  default     = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:ModifyVolume",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInstances",
                "ec2:DescribeSnapshots",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumesModifications"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": [
                        "CreateVolume",
                        "CreateSnapshot"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/CSIVolumeName": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/CSIVolumeName": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/kubernetes.io/created-for/pvc/name": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        }
    ]
}
EOF
}

## Security Group
variable "db_security_group_name" {
  type        = string
  default     = "seqera_db_security_group"
  description = "The name of the security group for the database."
}

variable "redis_security_group_name" {
  type        = string
  default     = "seqera_redis_security_group"
  description = "The name of the security group for Redis."
}

variable "seqera_irsa_role_name" {
  type        = string
  default     = "seqera-irsa-role"
  description = "The name of the IAM role for IRSA."
}

variable "seqera_irsa_iam_policy_name" {
  type        = string
  description = "The name of the IAM policy for IRSA."
  default     = "seqera-irsa-iam-policy"
}

## Database

variable "database_identifier" {
  type        = string
  default     = "seqera-db"
  description = "The identifier for the database."
}

variable "redis_cluster_name" {
  type        = string
  default     = "seqera-redis"
  description = "The name of the Redis cluster."
}

variable "db_engine_version" {
  type        = string
  default     = "5.7"
  description = "The version of the database engine."
}

variable "db_instance_class" {
  type        = string
  default     = "db.r5.xlarge"
  description = "The instance class for the database."
}

variable "db_allocated_storage" {
  type        = number
  default     = 10
  description = "The allocated storage size for the database."
}

variable "db_skip_final_snapshot" {
  type        = bool
  default     = true
  description = "Determines whether a final snapshot should be created when the database is deleted."
}

variable "db_name" {
  type        = string
  default     = "seqera"
  description = "The name of the database."
}

variable "db_username" {
  type        = string
  default     = "admin"
  description = "The username for the database."
}

variable "db_password" {
  type        = string
  default     = "my_db_password"
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file. The password provided will not be used if `manage_master_user_password` is set to true."
}

variable "db_port" {
  type        = string
  default     = "3306"
  description = "The port for the database."
}

variable "db_ingress_rule" {
  type        = string
  default     = "mysql-tcp"
  description = "The ingress rule for the database."
}

variable "db_manage_master_user_password" {
  type        = bool
  default     = false
  description = "Determines whether the master user password should be managed."
}

variable "db_iam_database_authentication_enabled" {
  type        = bool
  default     = false
  description = "Determines whether IAM database authentication is enabled for the database."
}

variable "db_maintenance_window" {
  type        = string
  default     = "Mon:00:00-Mon:03:00"
  description = "The maintenance window for the database."
}

variable "db_backup_window" {
  type        = string
  default     = "03:00-06:00"
  description = "The backup window for the database."
}

## DB Parameters
variable "db_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The list of database parameters."
  default = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}

## DB Options
variable "db_options" {
  type = list(object({
    option_name = string
    option_settings = list(object({
      name  = string
      value = string
    }))
  }))
  description = "The list of database options."
  default = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}


variable "db_monitoring_interval" {
  type        = string
  default     = "0"
  description = "The monitoring interval for the database."
}

variable "db_monitoring_role_name" {
  type        = string
  default     = "SeqeraRDSMonitoringRole"
  description = "The name of the IAM role used for database monitoring."
}

variable "db_create_monitoring_role" {
  type        = bool
  default     = false
  description = "Determines whether the monitoring role should be created."
}

variable "db_family" {
  type        = string
  default     = "mysql5.7"
  description = "The family of the database engine."
}

variable "db_major_engine_version" {
  type        = string
  default     = "5.7"
  description = "The major version of the database engine."
}

variable "db_deletion_protection" {
  type        = bool
  default     = false
  description = "Determines whether deletion protection is enabled for the database."
}

## Redis MemoryDB Cluster

## Redis Engine Version
variable "redis_engine_version" {
  type        = string
  description = "The version of the Redis engine."
  default     = "6.2"
}

## Redis Auto Minor Version Upgrade
variable "redis_auto_minor_version_upgrade" {
  type        = bool
  description = "Determines whether automatic minor version upgrades are enabled for Redis."
  default     = false
}

## Redis Node Type
variable "redis_node_type" {
  type        = string
  description = "The Redis node type."
  default     = "db.t4g.small"
}

## Redis Number of Shards
variable "redis_num_shards" {
  type        = number
  description = "The number of shards in the Redis cluster."
  default     = 2
}

## Redis Number of Replicas per Shard
variable "redis_num_replicas_per_shard" {
  type        = number
  description = "The number of replicas per shard in the Redis cluster."
  default     = 2
}

## Redis TLS Enabled
variable "redis_tls_enabled" {
  type        = bool
  description = "Determines whether TLS (Transport Layer Security) is enabled for Redis."
  default     = false
}

variable "redis_create_acl" {
  type        = bool
  default     = false
  description = "Determines whether an ACL should be created for Redis."
}

variable "redis_acl_name" {
  type    = string
  default = "open-access"
}

## Redis Maintenance Window
variable "redis_maintenance_window" {
  type        = string
  description = "The maintenance window for the Redis cluster."
  default     = "sun:23:00-mon:01:30"
}

## Redis Snapshot Retention Limit
variable "redis_snapshot_retention_limit" {
  type        = number
  description = "The number of days to retain Redis snapshots."
  default     = 7
}

## Redis Snapshot Window
variable "redis_snapshot_window" {
  type        = string
  description = "The window during which Redis snapshots are taken."
  default     = "05:00-09:00"
}

variable "redis_ingress_rule" {
  type        = string
  default     = "redis-tcp"
  description = "The ingress rule for the Redis cluster."
}

## Redis Users
variable "redis_users" {
  type = map(object({
    user_name     = string
    access_string = string
    passwords     = list(string)
    tags          = map(string)
  }))
  description = "A map of Redis user configurations."
  default = {
    admin = {
      user_name     = "seqera-admin-user"
      access_string = "on ~* &* +@all"
      passwords     = ["YouShouldPickAStrongSecurePassword987!"]
      tags          = { User = "admin" }
    }
    readonly = {
      user_name     = "seqera-readonly-user"
      access_string = "on ~* &* -@all +@read"
      passwords     = ["YouShouldPickAStrongSecurePassword123!"]
      tags          = { User = "readonly" }
    }
  }
}

## Redis Parameter Group
variable "redis_parameter_group_name" {
  type        = string
  description = "The name of the Redis parameter group."
  default     = "redis-param-group"
}

variable "redis_parameter_group_description" {
  type        = string
  description = "The description of the Redis parameter group."
  default     = "Redis MemoryDB parameter group"
}

variable "redis_parameter_group_family" {
  type        = string
  description = "The family of the Redis parameter group."
  default     = "memorydb_redis6"
}

variable "redis_parameter_group_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "A list of Redis parameter configurations."
  default = [
    {
      name  = "activedefrag"
      value = "yes"
    }
  ]
}

variable "redis_parameter_group_tags" {
  type        = map(string)
  description = "Tags to be applied to the Redis parameter group."
  default = {
    ParameterGroup = "custom"
  }
}

## Redis Subnet Group
variable "redis_create_subnet_group" {
  type        = bool
  description = "Determines whether to create a Redis subnet group."
  default     = true
}

variable "redis_subnet_group_name" {
  type        = string
  description = "The name of the Redis subnet group."
  default     = "seqera-redis-subnetgroup"
}

variable "redis_subnet_group_description" {
  type        = string
  description = "The description of the Redis subnet group."
  default     = "Seqera MemoryDB subnet group"
}

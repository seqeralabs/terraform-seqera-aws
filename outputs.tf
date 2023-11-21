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

output "database_url" {
  value       = try(module.db[0].db_instance_address, null)
  description = "Endpoint address for the primary RDS database instance."
}

output "redis_url" {
  value       = try(module.redis[0].endpoint, null)
  description = "Endpoint address for the Redis cluster. If not available, returns null."
}

output "seqera_irsa_role_name" {
  value       = try(module.seqera_irsa[0].iam_role_name, null)
  description = "IAM role name associated with Seqera IRSA (IAM Roles for Service Accounts)."
}

output "ec2_instance_id" {
  value       = try(module.ec2_instance.id, null)
  description = "EC2 instance ID."
}

output "ec2_instance_public_dns_name" {
  value       = try(module.ec2_instance.public_dns, null)
  description = "EC2 instance public DNS name."
}
# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "app_subnet_ids" {
  description = "IDs of the application subnets"
  value       = aws_subnet.app[*].id
}

output "app_subnet_cidrs" {
  description = "CIDR blocks of the application subnets"
  value       = aws_subnet.app[*].cidr_block
}

output "data_subnet_ids" {
  description = "IDs of the data subnets"
  value       = aws_subnet.data[*].id
}

output "data_subnet_cidrs" {
  description = "CIDR blocks of the data subnets"
  value       = aws_subnet.data[*].cidr_block
}

# Security Group Outputs
output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = aws_security_group.redis.id
}

output "connector_security_group_id" {
  description = "ID of the VPC Connector security group"
  value       = aws_security_group.vpc_connector.id
}

# NACL Outputs (for troubleshooting)
output "app_nacl_id" {
  description = "ID of the application subnets NACL"
  value       = aws_network_acl.app.id
}

output "data_nacl_id" {
  description = "ID of the data subnets NACL"
  value       = aws_network_acl.data.id
}

# VPC Connector Outputs
output "vpc_connector_arn" {
  description = "ARN of the App Runner VPC Connector"
  value       = aws_apprunner_vpc_connector.main.arn
}

output "connector_subnet_ids" {
  description = "Subnet IDs used by the VPC Connector (the misconfigured ones!)"
  value       = aws_apprunner_vpc_connector.main.subnets
}

# Redis Outputs
output "redis_endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_cluster_id" {
  description = "Redis cluster ID"
  value       = aws_elasticache_replication_group.redis.replication_group_id
}

# App Runner Outputs
output "app_runner_url" {
  description = "App Runner service URL"
  value       = "https://${aws_apprunner_service.main.service_url}"
}

output "app_runner_service_arn" {
  description = "App Runner service ARN"
  value       = aws_apprunner_service.main.arn
}

output "app_runner_service_id" {
  description = "App Runner service ID"
  value       = aws_apprunner_service.main.service_id
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL for pushing images"
  value       = aws_ecr_repository.app.repository_url
}

# Debugging Helper Outputs
output "debug_info" {
  description = "Quick debugging information"
  value = {
    vpc_connector_subnets = aws_apprunner_vpc_connector.main.subnets
    app_subnet_cidrs     = aws_subnet.app[*].cidr_block
    data_subnet_cidrs    = aws_subnet.data[*].cidr_block
    redis_endpoint       = aws_elasticache_replication_group.redis.primary_endpoint_address
    app_runner_url       = "https://${aws_apprunner_service.main.service_url}"
  }
}
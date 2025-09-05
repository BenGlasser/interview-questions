variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "terraform-challenge"
  
  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be <= 20 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "challenge"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for application subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition     = length(var.app_subnet_cidrs) >= 2
    error_message = "At least 2 app subnet CIDRs must be provided for multi-AZ deployment."
  }
}

variable "data_subnet_cidrs" {
  description = "CIDR blocks for data subnets (Redis)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
  
  validation {
    condition     = length(var.data_subnet_cidrs) >= 2
    error_message = "At least 2 data subnet CIDRs must be provided for multi-AZ deployment."
  }
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "app_runner_cpu" {
  description = "App Runner CPU units (0.25, 0.5, 1, 2, 4 vCPU)"
  type        = string
  default     = "1 vCPU"
}

variable "app_runner_memory" {
  description = "App Runner memory (512 MB to 8 GB)"
  type        = string
  default     = "2 GB"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (increases cost)"
  type        = bool
  default     = false
}
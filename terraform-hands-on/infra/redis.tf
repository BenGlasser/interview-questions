# Security Group for Redis
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = aws_vpc.main.id

  # Allow inbound Redis traffic from VPC Connector
  ingress {
    description     = "Redis from VPC Connector"
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_connector.id]
  }

  # Allow Redis cluster inter-node communication
  ingress {
    description = "Redis cluster communication"
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = aws_subnet.data[*].id

  tags = {
    Name = "${var.project_name}-redis-subnet-group"
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-redis"
  description                = "Redis cluster for ${var.project_name}"
  
  node_type                  = var.redis_node_type
  port                       = var.redis_port
  parameter_group_name       = "default.redis7"
  
  num_cache_clusters         = 1
  
  # Network configuration
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  
  # Disable auth for simplicity (not the root cause)
  auth_token_enabled         = false
  transit_encryption_enabled = false
  at_rest_encryption_enabled = true
  
  # Maintenance and backup
  maintenance_window         = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade = true
  
  # Cost optimization
  apply_immediately          = true
  
  tags = {
    Name = "${var.project_name}-redis"
  }
}
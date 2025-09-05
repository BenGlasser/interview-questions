# ECR Repository for the demo app
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false  # Reduce costs for demo
  }

  tags = {
    Name = "${var.project_name}-app-repo"
  }
}

# ECR Lifecycle Policy to limit image retention
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only 5 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Security Group for VPC Connector
resource "aws_security_group" "vpc_connector" {
  name        = "${var.project_name}-vpc-connector-sg"
  description = "Security group for App Runner VPC Connector"
  vpc_id      = aws_vpc.main.id

  # Allow outbound to Redis (this is CORRECT - SGs are not the issue)
  egress {
    description     = "Redis connection"
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.redis.id]
  }

  # Allow all other outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-connector-sg"
  }
}

# IAM Role for App Runner Service
resource "aws_iam_role" "apprunner_service" {
  name = "${var.project_name}-apprunner-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-apprunner-service-role"
  }
}

# IAM Role for App Runner Build/Access
resource "aws_iam_role" "apprunner_build" {
  name = "${var.project_name}-apprunner-build-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-apprunner-build-role"
  }
}

# IAM Policy for ECR access
resource "aws_iam_role_policy" "apprunner_ecr" {
  name = "${var.project_name}-apprunner-ecr-policy"
  role = aws_iam_role.apprunner_build.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# App Runner VPC Connector - THE MISCONFIGURATION!
# This connector is placed in the APP subnets whose NACLs block Redis traffic
resource "aws_apprunner_vpc_connector" "main" {
  vpc_connector_name = "${var.project_name}-vpc-connector"
  subnets           = aws_subnet.app[*].id  # BUG: Should use data subnets or fix NACLs
  security_groups   = [aws_security_group.vpc_connector.id]

  tags = {
    Name = "${var.project_name}-vpc-connector"
  }
}

# Generate a random suffix for the service name to avoid conflicts
resource "random_id" "service_suffix" {
  byte_length = 4
}

# App Runner Service
resource "aws_apprunner_service" "main" {
  service_name = "${var.project_name}-service-${random_id.service_suffix.hex}"

  source_configuration {
    image_repository {
      image_identifier      = "${aws_ecr_repository.app.repository_url}:latest"
      image_configuration {
        port = "3000"
        runtime_environment_variables = {
          REDIS_HOST     = aws_elasticache_replication_group.redis.primary_endpoint_address
          REDIS_PORT     = tostring(var.redis_port)
          REDIS_TLS      = "false"
          NODE_ENV       = "production"
        }
        runtime_environment_secrets = {}
      }
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu    = var.app_runner_cpu
    memory = var.app_runner_memory
    instance_role_arn = aws_iam_role.apprunner_service.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.main.arn
    }
  }

  health_check_configuration {
    healthy_threshold   = 1
    interval            = 10
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-service"
  }

  depends_on = [
    aws_iam_role_policy.apprunner_ecr
  ]
}
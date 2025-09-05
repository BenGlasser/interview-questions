# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Application Subnets (where VPC Connector will be placed - MISCONFIGURED!)
resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-app-subnet-${count.index + 1}"
    Type = "Application"
  }
}

# Data Subnets (where Redis will be placed)
resource "aws_subnet" "data" {
  count = length(var.data_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-data-subnet-${count.index + 1}"
    Type = "Data"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Associations for App Subnets
resource "aws_route_table_association" "app" {
  count = length(aws_subnet.app)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table for Private Subnets (Data)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route Table Associations for Data Subnets
resource "aws_route_table_association" "data" {
  count = length(aws_subnet.data)

  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private.id
}

# NAT Gateway (optional, for egress from private subnets)
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0
  
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0
  
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.app[0].id
  
  tags = {
    Name = "${var.project_name}-nat"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Add NAT route to private route table if NAT Gateway is enabled
resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? 1 : 0
  
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

# NETWORK ACLs - THE MISCONFIGURATION!

# NACL for App Subnets (BLOCKS Redis traffic!)
resource "aws_network_acl" "app" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.app[*].id

  # Allow HTTP/HTTPS inbound (for App Runner health checks and traffic)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral ports inbound (for return traffic)
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 32768
    to_port    = 65535
  }

  # Allow all outbound EXCEPT Redis traffic to data subnets!
  # This is the BUG - blocking Redis connections
  egress {
    rule_no    = 90  # Lower number = higher priority
    protocol   = "tcp"
    action     = "deny"
    cidr_block = "10.0.11.0/24"  # data subnet 1
    from_port  = 6379
    to_port    = 6379
  }

  egress {
    rule_no    = 91
    protocol   = "tcp"
    action     = "deny"
    cidr_block = "10.0.12.0/24"  # data subnet 2
    from_port  = 6379
    to_port    = 6379
  }

  # Allow all other outbound (after the DENY rules above)
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-app-nacl"
  }
}

# NACL for Data Subnets (More restrictive but correct)
resource "aws_network_acl" "data" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.data[*].id

  # Allow Redis inbound from app subnets
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.1.0/24"  # app subnet 1
    from_port  = 6379
    to_port    = 6379
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.2.0/24"  # app subnet 2
    from_port  = 6379
    to_port    = 6379
  }

  # Allow Redis cluster inter-node communication
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 6379
    to_port    = 6379
  }

  # Allow outbound ephemeral ports (for Redis responses)
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 32768
    to_port    = 65535
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.2.0/24"
    from_port  = 32768
    to_port    = 65535
  }

  # Allow Redis cluster outbound communication
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 6379
    to_port    = 6379
  }

  tags = {
    Name = "${var.project_name}-data-nacl"
  }
}
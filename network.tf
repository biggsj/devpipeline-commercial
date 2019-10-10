variable "cidr_core" {
  description = "CIDR block for the core network"
  default     = "172.19.0.0/24"
}

resource "aws_vpc" "core" {
  cidr_block           = var.cidr_core
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name} Core"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "core" {
  vpc_id = aws_vpc.core.id

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}

resource "aws_subnet" "core" {
  vpc_id                  = aws_vpc.core.id
  cidr_block              = var.cidr_core
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name    = "${var.project_name} Core"
    Project = var.project_name
  }
}

resource "aws_route_table" "core_public" {
  vpc_id = aws_vpc.core.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.core.id
  }

  tags = {
    Name    = "${var.project_name} Core Public"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "core_public" {
  subnet_id      = aws_subnet.core.id
  route_table_id = aws_route_table.core_public.id
}

resource "aws_security_group" "core" {
  name   = "core"
  vpc_id = aws_vpc.core.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"] # Use more specific CIDR to limit who can contact the swarm for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name} Core"
    Project = var.project_name
  }
}


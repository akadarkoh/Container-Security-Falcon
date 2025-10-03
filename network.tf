resource "aws_vpc" "falcon_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "falcon-vpc"
  }
}

resource "aws_internet_gateway" "falcon_igw" {
  vpc_id = aws_vpc.falcon_vpc.id

  tags = {
    Name = "falcon-igw"
  }
}

resource "aws_subnet" "falcon_public_subnet_a" {
  vpc_id                  = aws_vpc.falcon_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "falcon-public-subnet-a"
  }
}

resource "aws_subnet" "falcon_public_subnet_b" {
  vpc_id                  = aws_vpc.falcon_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "falcon-public-subnet-b"
  }
}

resource "aws_route_table" "falcon_public_rt" {
  vpc_id = aws_vpc.falcon_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.falcon_igw.id
  }

  tags = {
    Name = "falcon-public-rt"
  }
}

resource "aws_route_table_association" "falcon_public_assoc_a" {
  subnet_id      = aws_subnet.falcon_public_subnet_a.id
  route_table_id = aws_route_table.falcon_public_rt.id
}

resource "aws_route_table_association" "falcon_public_assoc_b" {
  subnet_id      = aws_subnet.falcon_public_subnet_b.id
  route_table_id = aws_route_table.falcon_public_rt.id
}

resource "aws_security_group" "falcon_alb_sg" {
  name        = "falcon-alb-sg"
  description = "Allow inbound HTTP to ALB"
  vpc_id      = aws_vpc.falcon_vpc.id

  ingress {
    description = "HTTP ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "falcon-alb-sg"
  }
}

resource "aws_security_group" "falcon_service_sg" {
  name        = "falcon-service-sg"
  description = "Allow ALB traffic to ECS service"
  vpc_id      = aws_vpc.falcon_vpc.id

  ingress {
    description     = "Allow ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.falcon_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "falcon-service-sg"
  }
}

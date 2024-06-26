provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "ionginx_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ionginx-vpc"
  }
}

# Availability Zones
data "aws_availability_zones" "available" {}

# Public Subnets
resource "aws_subnet" "public_subnet" {
  count = 3
  vpc_id = aws_vpc.ionginx_vpc.id
  cidr_block = cidrsubnet(aws_vpc.ionginx_vpc.cidr_block, 8, count.index + 1)
  map_public_ip_on_launch = true
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "ionginx-public-subnet-${count.index}"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  count = 3
  vpc_id = aws_vpc.ionginx_vpc.id
  cidr_block = cidrsubnet(aws_vpc.ionginx_vpc.cidr_block, 8, count.index + 4)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "ionginx-private-subnet-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ionginx_vpc.id
  tags = {
    Name = "ionginx-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet[0].id
  tags = {
    Name = "ionginx-nat-gateway"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ionginx_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "ionginx-public-rt"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public_rt_assoc" {
  count = 3
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ionginx_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "ionginx-private-rt"
  }
}

# Private Route Table Associations
resource "aws_route_table_association" "private_rt_assoc" {
  count = 3
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group
resource "aws_security_group" "nginx_sg" {
  vpc_id = aws_vpc.ionginx_vpc.id

  ingress {
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
    Name = "nginx-sg"
  }
}

# Launch Template
resource "aws_launch_template" "nginx_lt" {
  name_prefix   = "nginx-lt"
  image_id      = "ami-04b70fa74e45c3917" # Ubuntu Server 18.04 LTS
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.nginx_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "nginx-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "nginx_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = [for subnet in aws_subnet.private_subnet : subnet.id]

  launch_template {
    id      = aws_launch_template.nginx_lt.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "nginx-instance"
    propagate_at_launch = true
  }
}

# Route 53 Zone (assuming the domain is managed by Route 53)
resource "aws_route53_zone" "main" {
  name = "chandramani.com"
}

# Route 53 A Record
resource "aws_route53_record" "nginx_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.chandramani.com"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.nat_eip.public_ip]
}

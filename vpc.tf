#create a VPC for the cloudlaunch application

resource "aws_vpc" "cloudlaunch" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "cloudlaunch-vpc"
  }
}

#create public subnet (Intended for load balancers or future public-facing services.)

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.cloudlaunch.id
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name = "cloudlaunch-public-subnet"
  }
}

#Create private subnets (Intended for app servers (private)

resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.cloudlaunch.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "cloudlaunch-app-subnet"
  }
}



#create a database subnet (Intended for database servers (private))

resource "aws_subnet" "db" {
    vpc_id     = aws_vpc.cloudlaunch.id
    cidr_block = "10.0.3.0/28"

    tags = { Name = "cloudlaunch-db-subnet" }
  
}

# Create an Internet Gateway for the VPC (to allow internet access for public subnets)

resource    "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cloudlaunch.id

  tags = {
    Name = "cloudlaunch-igw"
  }
}

# Create a route table for public subnet (to route internet traffic)
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.cloudlaunch.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
tags = { Name = "cloudlaunch-public-rt" }
  
}

# Associate the public route table with the public subnet

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a route table for app subnet 
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.cloudlaunch.id

  tags = {
    Name = "cloudlaunch-app-rt"
  }
}

# Associate the app route table with the app subnet

resource "aws_route_table_association" "app_assoc" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.app.id
  
}

# Create a route table for db subnet
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.cloudlaunch.id

  tags = {
    Name = "cloudlaunch-db-rt"
  }
  
}

# Associate the db route table with the db subnet

resource "aws_route_table_association" "db_assoc" {
  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.db.id
  
}

# app security group (to allow HTTP traffic within the VPC only)
resource "aws_security_group" "app_sg" {
    name = "cloudlaunch-app-sg"
    vpc_id = aws_vpc.cloudlaunch.id
    description = "Allow http within the VPC only"
  
}

# Ingress rule for HTTP (80) from VPC CIDR
resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Egress rule to allow all outbound traffic (for app servers)
resource "aws_vpc_security_group_egress_rule" "app_all_egress" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol = "-1"
}

# create db security group (to allow MySQL traffic from app subnet only)
resource "aws_security_group" "db_sg" {
  name = "cloudlaunch-db-sg"
  vpc_id = aws_vpc.cloudlaunch.id
  description = "Allow MySQL from App subnet only"

}

# Ingress rule for MySQL (3306) from app subnet CIDR
resource "aws_vpc_security_group_ingress_rule" "db_mysql" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = aws_subnet.app.cidr_block
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
  
}

# Egress rule to allow all outbound traffic (for db servers)
resource "aws_vpc_security_group_egress_rule" "db_all_egress" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  
}





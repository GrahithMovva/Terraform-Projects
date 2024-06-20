terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
    region = "ap-south-1"
}


resource "aws_vpc" "main_vpc" {
  cidr_block = "10.99.0.0/16"
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.99.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet 1"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.99.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subney 2"
  }
}

resource "aws_subnet" "subnet-3" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.99.2.0/24"
  availability_zone = "ap-south-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet 3"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "main-rt-table" {
  vpc_id = aws_vpc.main_vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.main-rt-table.id
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.main-rt-table.id
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet-3.id
  route_table_id = aws_route_table.main-rt-table.id
}

resource "aws_security_group" "node-red-group" {
  name = "allow node-red traffic"
  vpc_id = aws_vpc.main_vpc.id

  ingress{
    from_port = 1880
    to_port = 1880
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Node-red security group"
  }
}

resource "aws_security_group" "fast-api-group" {
  name = "allow fast-api traffic"
  vpc_id = aws_vpc.main_vpc.id

  ingress{
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["10.99.0.0/24", "10.99.2.0/24"]
    security_groups = [aws_security_group.node-red-group.id,aws_security_group.rds-group.id]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Fast-API security group"
  }
}

resource "aws_security_group" "rds-group" {
  name = "allow rds traffic"
  vpc_id = aws_vpc.main_vpc.id

  ingress{
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.99.1.0/24"]
    security_groups = [aws_security_group.fast-api-group.id]
  }

  egress{
    from_port = 3306
    to_port = 3306
    protocol = "-tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "RDS security group"
  }
}

resource "aws_security_group" "sub3-group" {
  name = "no inbound traffic"
  vpc_id = aws_vpc.main_vpc.id

  egress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["10.99.1.0/24"]
    security_groups = [aws_security_group.fast-api-group.id]
  }
  
  tags = {
    Name = "no inbound traffic group"
  }
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet-3.id, aws_subnet.subnet-3.id]
}

resource "aws_db_instance" "DB" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "grahith"
  password             = "123456789"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds-group.id]
  db_subnet_group_name = aws_db_subnet_group.db-subnet-group.name

  tags = {
    Name = "MySQL Database"
  }
}

resource "aws_instance" "node-red" {
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.node-red-group.id]
  key_name = "EC2First"
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                EOF

  tags = {
    Name = "Node Red server"
  }
}

resource "aws_instance" "fast-api" {
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.fast-api-group.id]
  key_name = "EC2First"
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                EOF

  tags = {
    Name = "Fast-API server"
  }
}

resource "aws_instance" "nginx" {
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.sub3-group.id]
  key_name = "EC2First"
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                EOF

  tags = {
    Name = "nginx"
  }
}

resource "aws_eip" "lb" {
  instance = aws_instance.node-red.id
  domain   = "vpc"
}

resource "aws_eip" "2b" {
  instance = aws_instance.fast-api.ip
  domain   = "vpc"
}

resource "aws_eip" "3b" {
  instance = aws_instance.nginx.id
  domain   = "vpc"
}
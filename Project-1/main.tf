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
  username             = "username"
  password             = "password"
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
              # Update the package repository
              sudo apt-get update

              # Install Node.js and npm
              sudo apt-get install -y nodejs npm

              # Install Node-RED globally
              sudo npm install -g --unsafe-perm node-red

              # Create a systemd service file for Node-RED
              echo "[Unit]
              Description=Node-RED
              After=network.target

              [Service]
              ExecStart=/usr/bin/node-red
              Restart=on-failure
              User=ubuntu
              Group=ubuntu
              Environment="NODE_RED_OPTIONS=-v"

              [Install]
              WantedBy=multi-user.target" | sudo tee /etc/systemd/system/node-red.service

              # Reload systemd and enable the Node-RED service
              sudo systemctl daemon-reload
              sudo systemctl enable node-red
              sudo systemctl start node-red
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
              # Update the package repository
              sudo apt-get update

              # Install Python3 and pip
              sudo apt-get install -y python3 python3-pip

              # Install FastAPI and Uvicorn
              sudo pip3 install fastapi uvicorn

              # Create a sample FastAPI app
              echo "from fastapi import FastAPI

              app = FastAPI()

              @app.get('/')
              def read_root():
                  return {'Hello': 'World'}" > /home/ubuntu/main.py

              # Create a systemd service file for FastAPI
              echo "[Unit]
              Description=FastAPI
              After=network.target

              [Service]
              ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000
              WorkingDirectory=/home/ubuntu
              Restart=always
              User=ubuntu

              [Install]
              WantedBy=multi-user.target" | sudo tee /etc/systemd/system/fastapi.service

              # Reload systemd and enable the FastAPI service
              sudo systemctl daemon-reload
              sudo systemctl enable fastapi
              sudo systemctl start fastapi
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
              # Update the package repository
              sudo apt-get update

              # Install Nginx
              sudo apt-get install -y nginx

              # Start and enable Nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
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
  instance = aws_instance.fast-api.id
  domain   = "vpc"
}

resource "aws_eip" "3b" {
  instance = aws_instance.nginx.id
  domain   = "vpc"
}
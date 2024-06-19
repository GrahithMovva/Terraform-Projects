terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "main-vpc"
#   }
# }

# resource "aws_instance" "first" {
#   ami = "ami-0e1d06225679bc1c5"
#   instance_type = "t2.micro"
  
#   tags = {
#     Name = "linux qwerty"
#   }
# }

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   gat = aws_internet_gateway.igw.id
  # }

  tags = {
    Name = "main route table"
  }
}

resource "aws_subnet" "subnet-1-a" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "subnet 1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1-a.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv4         = ["0.0.0.0/0"]
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443

  

#   tags = {
#     Name = "HTTPS"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv4         = ["0.0.0.0/0"]
#   from_port         = 80
#   ip_protocol       = "tcp"
#   to_port           = 80

  
#   tags = {
#     Name = "HTTP"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv4         = ["0.0.0.0/0"]
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22

  
#   tags = {
#     Name = "HTTP"
#   }
# }

# # resource "aws_vpc_security_group_ingress_rule" "allow_web_ipv6" {
# #   security_group_id = aws_security_group.allow_tls.id
# #   cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
# #   from_port         = 443
# #   ip_protocol       = "tcp"
# #   to_port           = 443

# #   tags = {
# #     Name = "HTTPS"
# #   }
# # }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }


resource "aws_network_interface" "web-server" {
  subnet_id       = aws_subnet.subnet-1-a.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}

resource "aws_eip" "lb" {
  domain   = "vpc"
  network_interface = aws_network_interface.web-server.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.igw ]
}


resource "aws_instance" "web" {
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "EC2First"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                EOF

  tags = {
    Name = "First web server"
  }

  

}
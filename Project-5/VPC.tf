resource "aws_vpc" "Main_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.Main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet-2" {
  vpc_id                  = aws_vpc.Main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Main_vpc.id

}

resource "aws_route_table" "main-rt-table" {
  vpc_id = aws_vpc.Main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  route_table_id = aws_route_table.main-rt-table.id
  subnet_id      = aws_subnet.subnet-1.id
}

resource "aws_route_table_association" "b" {
  route_table_id = aws_route_table.main-rt-table.id
  subnet_id      = aws_subnet.subnet-2.id
}
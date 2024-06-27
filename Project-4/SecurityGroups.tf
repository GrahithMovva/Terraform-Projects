resource "aws_security_group" "VerneMQ-group" {
  name        = "allow MQTT traffic"
  description = "Allow MQTT traffic"
  vpc_id      = aws_vpc.Main_vpc.id

  ingress {
    from_port   = 1880
    to_port     = 1880
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
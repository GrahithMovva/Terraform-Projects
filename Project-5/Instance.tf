resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  db_name              = jsondecode(aws_secretsmanager_secret_version.sec-version.secret_string)["dbname"]
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = jsondecode(aws_secretsmanager_secret_version.sec-version.secret_string)["username"]
  password             = jsondecode(aws_secretsmanager_secret_version.sec-version.secret_string)["password"]
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}


resource "aws_instance" "VerneMQ" {
  ami             = "ami-0f58b397bc5c1f2e8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.VerneMQ-group.id]
  key_name        = "EC2First"
  user_data       = <<-EOF
                #!/bin/bash
                # Update the package list
                yum update -y
                # Install Docker
                amazon-linux-extras install docker -y
                # Start Docker service
                service docker start
                # Add ec2-user to the docker group so you can execute Docker commands without using sudo
                usermod -a -G docker ec2-user
                # Enable Docker service to start on boot
                chkconfig docker on
                docker pull erlio/docker-vernemq
                EOF

  tags = {
    Name = "VerneMQ"
  }
}

resource "aws_iam_role" "VerneMQ-role" {
  name               = "IAM_role_VerneMQ"
  assume_role_policy = <<EOF
    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF

}

resource "aws_iam_policy" "lambda-invoke-policy" {
  name        = "lambda_invoke_policy_VerneMQ"
  description = "IAM policy for the VerneMQ instance to invoke a lambda function"
  policy      = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunctionUrl",
                "lambda:InvokeFunction",
                "lambda:InvokeAsync"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "ivoke-policy-VerneMQ-attach" {
  role       = aws_iam_role.VerneMQ-role.name
  policy_arn = aws_iam_policy.lambda-invoke-policy.arn

}


resource "aws_instance" "grafana" {
  ami             = "ami-0f58b397bc5c1f2e8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.subnet-2.id
  security_groups = [aws_security_group.grafana-group.i]
  key_name        = "EC2First"
  user_data       = <<-EOF
                #!/bin/bash
                # Update the package list
                yum update -y
                # Install Docker
                amazon-linux-extras install docker -y
                # Start Docker service
                service docker start
                # Add ec2-user to the docker group so you can execute Docker commands without using sudo
                usermod -a -G docker ec2-user
                # Enable Docker service to start on boot
                chkconfig docker on
                docker pull grafana/grafana
                EOF

  tags = {
    Name = "Grafana"
  }
}
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  db_name              = "mydb"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = aws_secretsmanager_secret_version.rds-secret.secret_string["password"]
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

resource "aws_secretsmanager_secret" "rds-secret" {
  name = "rds-credentials"
}


resource "aws_secretsmanager_secret_version" "sec-version" {
  secret_id = aws_secretsmanager_secret.rds-secret.id

  secret_string = jsonencode({
    username = "admin"
    password = "examplepassword"
  })
}


output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  db_name              = "mydb"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = aws_secretsmanager_secret_version.sec-version.secret_string
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

}

resource "random_password" "rand_password" {
  length  = 10
  special = true
  numeric = true
  upper   = true
  lower   = true
}

resource "aws_secretsmanager_secret" "rds-secret" {
  name = "rds-password"

}


resource "aws_secretsmanager_secret_version" "sec-version" {
  secret_id = aws_secretsmanager_secret.rds-secret.id

  secret_string = random_password.rand_password.result
}


resource "aws_secretsmanager_secret_rotation" "rotation" {
  secret_id           = aws_secretsmanager_secret.rds-secret.id
  rotation_lambda_arn = aws_lambda_function.secretManager-lamdba.arn

  rotation_rules {
    automatically_after_days = 7
  }
}

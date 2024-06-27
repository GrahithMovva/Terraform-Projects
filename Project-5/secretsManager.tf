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

  secret_string = jsonencode({
    password = "${random_password.rand_password.result}"
    username = "admin"
    dbname   = "mydb"

  })
}




resource "aws_secretsmanager_secret_rotation" "rotation" {
  secret_id           = aws_secretsmanager_secret.rds-secret.id
  rotation_lambda_arn = aws_lambda_function.secretManager-lamdba.arn

  rotation_rules {
    automatically_after_days = 7
  }
}

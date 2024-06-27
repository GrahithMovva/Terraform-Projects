resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  db_name              = "mydb"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = jsondecode(aws_secretsmanager_secret_version.sec-version.secret_string)["password"]
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
  name = "rds-credentialssss"

}


resource "aws_secretsmanager_secret_version" "sec-version" {
  secret_id = aws_secretsmanager_secret.rds-secret.id

  secret_string = jsonencode({
    password = "examplepass"
    username = "admin"
    dbname = "mydb"

  })
}

resource "aws_secretsmanager_secret_rotation" "rotation" {
  secret_id           = aws_secretsmanager_secret.rds-secret.id
  rotation_lambda_arn = aws_lambda_function.secretManager-lamdba.arn

  rotation_rules {
    automatically_after_days = 7
  }
}

# data "aws_iam_policy_document" "invoke-policy-document" {
#   statement {
#     sid    = "VisualEditor0"
#     effect = "Allow"

#   principals {
#     type        = "AWS"
#     identifiers = ["arn:aws:iam::654797133855:root"]
#   }

#     actions   = ["lambda:InvokeFunctionUrl",
#                 "lambda:InvokeFunction",
#                 "lambda:InvokeAsync"]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "policy-invoke-lambda" {
#   name        = "lambda-invoke-policy"
#   description = "secrets manager policy for the lambda function"

#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "VisualEditor0",
#             "Effect": "Allow",
#             "Action": [
#                 "lambda:InvokeFunctionUrl",
#                 "lambda:InvokeFunction",
#                 "lambda:InvokeAsync"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# EOF
# }

# resource "aws_secretsmanager_secret_policy" "invoke" {
#   secret_arn = aws_secretsmanager_secret.rds-secret.arn
#   policy = data.aws_iam_policy_document.invoke-policy-document.json

# }
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "secretManager-RDS-lamdba" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_RDS_handler"
  handler       = "lambda_RDS_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda-1-role.arn
  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
  environment {
    variables = {
      SECRET_NAME = "rds-credentials"
      REGION_NAME = "ap-south-1"
      DB_HOST = aws_db_instance.mysql.address
    }
  }

}

resource "aws_lambda_permission" "allow_secretManager" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secretManager-lamdba.function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_lambda_function" "secretManager-lamdba" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_SM_handler"
  handler       = "lambda_SM_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.iam_for_lambda.arn


  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
  environment {
    variables = {
      SECRET_NAME = "rds-credentials"
    }
  }

}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "secretsmanager.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}





resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json


}

resource "aws_iam_role" "lambda-1-role" {
  name        = "example_lambda_exec_role"
  description = "Execution role for the lambda function"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# resource "aws_iam_role" "lambda-2-role" {
#   name        = "example_lambda2_exec_role"
#   description = "Execution role for the lambda function"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Id": "default",
#   "Statement": [
#     {
#       "Sid": "SecretsManagerRDSMySQLRotationSingleUser3fb-SecretRotationScheduleHost-LambdaPermission-FRv0GuDPEta7",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "secretsmanager.amazonaws.com"
#       },
#       "Action": "lambda:InvokeFunction",
#       "Resource": "arn:aws:lambda:ap-south-1:654797133855:function:lambda_SM_handler",
#       "Condition": {
#         "StringEquals": {
#           "AWS:SourceAccount": "654797133855"
#         }
#       }
#     }
#   ]
# }
# EOF

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "secretsmanager.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

resource "aws_iam_policy" "policy-rotation-1" {
  name        = "rotation_1_lambda_policy"
  description = "secrets manager policy for the lambda function"

  policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"ec2:CreateNetworkInterface",
				"ec2:DeleteNetworkInterface",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DetachNetworkInterface"
			],
			"Resource": "*",
			"Effect": "Allow"
		}
	]
}
EOF
}

resource "aws_iam_policy" "policy-rotation-2" {
  name        = "rotaion_2_lambda_policy"
  description = "secrets manager policy for the lambda function"

  policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
		{

			"Action": [
				"secretsmanager:DescribeSecret",
				"secretsmanager:GetSecretValue",
				"secretsmanager:PutSecretValue",
				"secretsmanager:UpdateSecretVersionStage"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": [
				"secretsmanager:GetRandomPassword"
			],
			"Resource": "*",
			"Effect": "Allow"
		}
	]
}
EOF
}

# resource "aws_iam_policy" "policy-rotation-3" {
#   name        = "rotaion_3_lambda_policy"
#   description = "secrets manager policy for the lambda function"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Id": "default",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "secretsmanager.amazonaws.com"
#       },
#       "Action": "lambda:InvokeFunction",
#       "Resource": "*",
#       "Condition": {
#         "StringEquals": {
#           "AWS:SourceAccount": "654797133855"
#         }
#       }
#     }
#   ]
# }
# EOF
# }

resource "aws_iam_policy" "policy-2" {
  name        = "lambda-rds-write-access-policy"
  description = "Policy for Lambda to access RDS"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "rds:DeleteBlueGreenDeployment",
                "rds:StartDBCluster",
                "rds:DeleteGlobalCluster",
                "rds:RestoreDBInstanceFromS3",
                "rds:ResetDBParameterGroup",
                "rds:CrossRegionCommunication",
                "rds:RebootDBShardGroup",
                "rds:ModifyDBProxyEndpoint",
                "rds:PurchaseReservedDBInstancesOffering",
                "rds:CreateDBSubnetGroup",
                "rds:DescribeRecommendations",
                "rds:ModifyCustomDBEngineVersion",
                "rds:ModifyDBParameterGroup",
                "rds:ModifyDBShardGroup",
                "rds:DownloadDBLogFilePortion",
                "rds:AddRoleToDBCluster",
                "rds:DeleteDBInstance",
                "rds:ModifyDBRecommendation",
                "rds:DeleteIntegration",
                "rds:DeleteDBProxy",
                "rds:DeleteDBInstanceAutomatedBackup",
                "rds:CreateDBSnapshot",
                "rds:DeleteDBSecurityGroup",
                "rds:ModifyRecommendation",
                "rds:CreateEventSubscription",
                "rds:ModifyTenantDatabase",
                "rds:DeleteDBShardGroup",
                "rds:DeleteOptionGroup",
                "rds:FailoverDBCluster",
                "rds:AddRoleToDBInstance",
                "rds:ModifyDBProxy",
                "rds:CreateDBInstance",
                "rds:DescribeRecommendationGroups",
                "rds:ModifyActivityStream",
                "rds:DeleteDBCluster",
                "rds:StartDBInstanceAutomatedBackupsReplication",
                "rds:ModifyEventSubscription",
                "rds:ModifyDBProxyTargetGroup",
                "rds:RebootDBCluster",
                "rds:ModifyDBSnapshot",
                "rds:DeleteDBClusterSnapshot",
                "rds:ListTagsForResource",
                "rds:CreateDBCluster",
                "rds:DeleteDBClusterParameterGroup",
                "rds:ApplyPendingMaintenanceAction",
                "rds:BacktrackDBCluster",
                "rds:RemoveRoleFromDBInstance",
                "rds:ModifyDBSubnetGroup",
                "rds:FailoverGlobalCluster",
                "rds:RemoveRoleFromDBCluster",
                "rds:DeleteTenantDatabase",
                "rds:CreateGlobalCluster",
                "rds:DeregisterDBProxyTargets",
                "rds:CreateOptionGroup",
                "rds:ModifyIntegration",
                "rds:CreateDBProxyEndpoint",
                "rds:AddSourceIdentifierToSubscription",
                "rds:CopyDBParameterGroup",
                "rds:CreateDBProxy",
                "rds:ModifyDBClusterParameterGroup",
                "rds:ModifyDBInstance",
                "rds:RegisterDBProxyTargets",
                "rds:ModifyDBClusterSnapshotAttribute",
                "rds:CopyDBClusterParameterGroup",
                "rds:CreateDBClusterEndpoint",
                "rds:StopDBCluster",
                "rds:CreateDBParameterGroup",
                "rds:CancelExportTask",
                "rds:CreateBlueGreenDeployment",
                "rds:DeleteDBSnapshot",
                "rds:RemoveFromGlobalCluster",
                "rds:DeleteCustomDBEngineVersion",
                "rds:PromoteReadReplica",
                "rds:StartDBInstance",
                "rds:StopActivityStream",
                "rds:RestoreDBClusterFromS3",
                "rds:DeleteDBSubnetGroup",
                "rds:RestoreDBInstanceFromDBSnapshot",
                "rds:ModifyDBClusterEndpoint",
                "rds:CreateDBShardGroup",
                "rds:ModifyDBCluster",
                "rds:DeleteDBParameterGroup",
                "rds:CreateDBClusterSnapshot",
                "rds:CreateDBClusterParameterGroup",
                "rds:ModifyDBSnapshotAttribute",
                "rds:DisableHttpEndpoint",
                "rds:PromoteReadReplicaDBCluster",
                "rds:ModifyOptionGroup",
                "rds:RestoreDBClusterFromSnapshot",
                "rds:StartExportTask",
                "rds:StartActivityStream",
                "rds:StopDBInstanceAutomatedBackupsReplication",
                "rds:DeleteEventSubscription",
                "rds:RemoveSourceIdentifierFromSubscription",
                "rds:DeleteDBProxyEndpoint",
                "rds:DeleteDBClusterEndpoint",
                "rds:RevokeDBSecurityGroupIngress",
                "rds:ModifyCurrentDBClusterCapacity",
                "rds:ResetDBClusterParameterGroup",
                "rds:RestoreDBClusterToPointInTime",
                "rds:CreateCustomDBEngineVersion",
                "rds:CreateIntegration",
                "rds:CopyDBSnapshot",
                "rds:CopyDBClusterSnapshot",
                "rds:SwitchoverBlueGreenDeployment",
                "rds:StopDBInstance",
                "rds:CopyOptionGroup",
                "rds:DeleteDBClusterAutomatedBackup",
                "rds:SwitchoverReadReplica",
                "rds:ModifyCertificates",
                "rds:CreateDBSecurityGroup",
                "rds:RebootDBInstance",
                "rds:ModifyGlobalCluster",
                "rds:EnableHttpEndpoint",
                "rds:DownloadCompleteDBLogFile",
                "rds:CreateDBInstanceReadReplica",
                "rds:SwitchoverGlobalCluster",
                "rds:CreateTenantDatabase",
                "rds:RestoreDBInstanceToPointInTime"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy-1-attach" {
  role       = aws_iam_role.lambda-1-role.name
  policy_arn = aws_iam_policy.policy-rotation-2.arn

}

resource "aws_iam_role_policy_attachment" "policy-2-attach" {
  role       = aws_iam_role.lambda-1-role.name
  policy_arn = aws_iam_policy.policy-2.arn

}

resource "aws_iam_role_policy_attachment" "lambda-2-rotation-policy-1-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy-rotation-1.arn

}

resource "aws_iam_role_policy_attachment" "lambda-2-rotation-policy-arn-1-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"

}

resource "aws_iam_role_policy_attachment" "lambda-2-rotation-policy-arn-2-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}

resource "aws_iam_role_policy_attachment" "lambda-2-rotation-policy-2-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy-rotation-2.arn

}

# resource "aws_iam_role_policy_attachment" "lambda-2-rotation-policy-3-attach" {
#   role       = aws_iam_role.lambda-2-role.name
#   policy_arn = aws_iam_policy.policy-rotation-3.arn

# }


data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "secretManager-RDS-lamdba" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_RDS_handler"
  handler       = "index.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda-1-role.arn

  environment {
    variables = {
      SECRET_NAME = ""
      REGION_NAME = "ap-south-1"
    }
  }

}

resource "aws_lambda_function" "secretManager-lamdba" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_SM_handler"
  handler       = "index.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda-2-role.arn

  environment {
    variables = {
      SECRET_NAME = ""
    }
  }
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

resource "aws_iam_role" "lambda-2-role" {
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

resource "aws_iam_policy" "policy-1" {
  name        = "example_lambda_policy"
  description = "Policy for the lambda function"

  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BasePermissions",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:*",
                "cloudformation:CreateChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:DescribeStackResource",
                "cloudformation:DescribeStacks",
                "cloudformation:ExecuteChangeSet",
                "docdb-elastic:GetCluster",
                "docdb-elastic:ListClusters",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "kms:DescribeKey",
                "kms:ListAliases",
                "kms:ListKeys",
                "lambda:ListFunctions",
                "rds:DescribeDBClusters",
                "rds:DescribeDBInstances",
                "redshift:DescribeClusters",
                "redshift-serverless:ListWorkgroups",
                "redshift-serverless:GetNamespace",
                "tag:GetResources"
            ],
            "Resource": "*"
        },
        {
            "Sid": "LambdaPermissions",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:CreateFunction",
                "lambda:GetFunction",
                "lambda:InvokeFunction",
                "lambda:UpdateFunctionConfiguration"
            ],
            "Resource": "arn:aws:lambda:*:*:function:SecretsManager*"
        },
        {
            "Sid": "SARPermissions",
            "Effect": "Allow",
            "Action": [
                "serverlessrepo:CreateCloudFormationChangeSet",
                "serverlessrepo:GetApplication"
            ],
            "Resource": "arn:aws:serverlessrepo:*:*:applications/SecretsManager*"
        },
        {
            "Sid": "S3Permissions",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::awsserverlessrepo-changesets*",
                "arn:aws:s3:::secrets-manager-rotation-apps-*/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "policy-2" {
  name        = "lambda-rds-write-access-policy"
  description = "Policy for Lambda to access RDS"

  policy      = <<EOF
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
    role = aws_iam_role.lambda-1-role.name
    policy_arn = aws_iam_policy.policy-1.arn
  
}

resource "aws_iam_role_policy_attachment" "policy-2-attach" {
    role = aws_iam_role.lambda-1-role.name
    policy_arn = aws_iam_policy.policy-2.arn
  
}

resource "aws_iam_role_policy_attachment" "lambda-2-policy-1-attach" {
    role = aws_iam_role.lambda-2-role.name
    policy_arn = aws_iam_policy.policy-1.arn
  
}


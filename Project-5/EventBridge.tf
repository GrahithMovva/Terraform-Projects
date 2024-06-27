resource "aws_cloudwatch_event_rule" "minute" {
  name                = "each_minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_rule" "Hour" {
  name                = "each_Hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "minute_lambda_target" {
  rule      = aws_cloudwatch_event_rule.minute.name
  target_id = "lambda"
  arn       = aws_lambda_function.RDS-Data-procesing-lamdba.arn
}

resource "aws_cloudwatch_event_target" "hour_lambda_target" {
  rule      = aws_cloudwatch_event_rule.Hour.name
  target_id = "lambda"
  arn       = aws_lambda_function.RDS-Data-procesing-lamdba.arn
}
resource "aws_dynamodb_table" "messages" {
  name           = "${var.project_name}-messages"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "message_id"

  attribute {
    name = "message_id"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-dynamodb-table"
  }
}

# Update IAM role to allow ECS task to access DynamoDB
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "${var.project_name}-dynamodb-policy"
  path        = "/"
  description = "IAM policy for ECS task to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Scan"
      ]
      Effect   = "Allow"
      Resource = aws_dynamodb_table.messages.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

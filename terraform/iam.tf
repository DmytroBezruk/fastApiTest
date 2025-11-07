# Check if the IAM role already exists
data "aws_iam_role" "existing_role" {
  name = "fastapi_lambda_exec_role"
}

# Conditionally create IAM role only if it doesn't exist
resource "aws_iam_role" "lambda_role" {
  count = length(try(data.aws_iam_role.existing_role.name, [])) == 0 ? 1 : 0

  name = "fastapi_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "states.amazonaws.com"]
        }
      }
    ]
  })
}

# Attach policies only if the role is being created
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count      = length(aws_iam_role.lambda_role) == 0 ? 0 : 1
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_execute_permissions" {
  count      = length(aws_iam_role.lambda_role) == 0 ? 0 : 1
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "step_functions_full_access" {
  count      = length(aws_iam_role.lambda_role) == 0 ? 0 : 1
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

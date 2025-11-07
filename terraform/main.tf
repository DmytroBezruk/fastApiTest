provider "aws" {
  region = var.aws_region
}

locals {
  build_path = "${path.module}/../build"
}

# Lambda One
resource "aws_lambda_function" "lambda_one" {
  function_name = "lambda_one"
  role          = length(aws_iam_role.lambda_role) > 0 ? aws_iam_role.lambda_role[0].arn : data.aws_iam_role.existing_role.arn
  handler       = "lambda_one.lambda_handler"
  runtime       = "python3.12"

  filename         = "${local.build_path}/lambda_one.zip"
  source_code_hash = filebase64sha256("${local.build_path}/lambda_one.zip")
}

# Lambda Two
resource "aws_lambda_function" "lambda_two" {
  function_name = "lambda_two"
  role          = length(aws_iam_role.lambda_role) > 0 ? aws_iam_role.lambda_role[0].arn : data.aws_iam_role.existing_role.arn
  handler       = "lambda_two.lambda_handler"
  runtime       = "python3.12"

  filename         = "${local.build_path}/lambda_two.zip"
  source_code_hash = filebase64sha256("${local.build_path}/lambda_two.zip")
}

# Step Function
resource "aws_sfn_state_machine" "example" {
  name     = "fastapi_step_function"
  role_arn = length(aws_iam_role.lambda_role) > 0 ? aws_iam_role.lambda_role[0].arn : data.aws_iam_role.existing_role.arn

  type     = "EXPRESS"

  definition = jsonencode({
    Comment = "Step Function chaining two Lambdas",
    StartAt = "LambdaOne",
    States = {
      LambdaOne = {
        Type     = "Task",
        Resource = aws_lambda_function.lambda_one.arn,
        Next     = "LambdaTwo"
      },
      LambdaTwo = {
        Type     = "Task",
        Resource = aws_lambda_function.lambda_two.arn,
        End      = true
      }
    }
  })
}

# Output
output "step_function_arn" {
  value = aws_sfn_state_machine.example.arn
}

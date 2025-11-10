provider "aws" {
  region = var.aws_region
}

locals {
  build_path = "${path.module}/../build"

  # Determine which resources to create based on existence checks
  create_lambda_one = var.create_lambda_one
  create_lambda_two = var.create_lambda_two
  create_step_function = var.create_step_function
}

# Lambda One
resource "aws_lambda_function" "lambda_one" {
  count = local.create_lambda_one ? 1 : 0

  function_name = "lambda_one"
  role          = length(aws_iam_role.lambda_role) > 0 ? aws_iam_role.lambda_role[0].arn : data.aws_iam_role.existing_role.arn
  handler       = "lambda_one.lambda_handler"
  runtime       = "python3.12"

  filename         = "${local.build_path}/lambda_one.zip"
  source_code_hash = filebase64sha256("${local.build_path}/lambda_one.zip")
}

# Lambda Two
resource "aws_lambda_function" "lambda_two" {
  count = local.create_lambda_two ? 1 : 0

  function_name = "lambda_two"
  role          = length(aws_iam_role.lambda_role) > 0 ? aws_iam_role.lambda_role[0].arn : data.aws_iam_role.existing_role.arn
  handler       = "lambda_two.lambda_handler"
  runtime       = "python3.12"

  filename         = "${local.build_path}/lambda_two.zip"
  source_code_hash = filebase64sha256("${local.build_path}/lambda_two.zip")
}

# Step Function
resource "aws_sfn_state_machine" "example" {
  count = local.create_step_function ? 1 : 0

  name     = "fastapi_step_function"
  role_arn = length(aws_iam_role.lambda_role) > 0 ? aws_iam_role.lambda_role[0].arn : data.aws_iam_role.existing_role.arn

  type     = "EXPRESS"

  definition = jsonencode({
    Comment = "Step Function chaining two Lambdas",
    StartAt = "LambdaOne",
    States = {
      LambdaOne = {
        Type     = "Task",
        Resource = local.create_lambda_one ? aws_lambda_function.lambda_one[0].arn : data.aws_lambda_function.existing_lambda_one[0].arn
        Next     = "LambdaTwo"
      },
      LambdaTwo = {
        Type     = "Task",
        Resource = local.create_lambda_two ? aws_lambda_function.lambda_two[0].arn : data.aws_lambda_function.existing_lambda_two[0].arn
        End      = true
      }
    }
  })
}

# Output
output "step_function_arn" {
  value = local.create_step_function ? aws_sfn_state_machine.example[0].arn : data.aws_sfn_state_machine.existing_step_function[0].arn
}
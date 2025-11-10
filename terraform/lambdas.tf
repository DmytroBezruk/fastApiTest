locals {
  lambda_source_dir = "../lambdas"
}

data "archive_file" "lambda_one_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_one.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_two_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_two.zip"
  excludes    = ["__pycache__"]
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_one" {
  function_name = "${var.project_name}-lambda-one-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_one.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_one_zip.output_path
  source_code_hash = data.archive_file.lambda_one_zip.output_base64sha256
  timeout       = 10
  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

resource "aws_lambda_function" "lambda_two" {
  function_name = "${var.project_name}-lambda-two-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_two.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_two_zip.output_path
  source_code_hash = data.archive_file.lambda_two_zip.output_base64sha256
  timeout       = 10
  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}


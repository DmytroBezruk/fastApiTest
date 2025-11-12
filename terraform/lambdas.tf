locals {
  lambda_source_dir = "../lambdas"
}

# Create individual ZIPs per lambda containing only needed files.
# Using separate archive_file data sources referencing a temporary staging directory is optional; we package entire folder for simplicity.

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

data "archive_file" "lambda_words_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_words.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_compute_product_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_compute_product.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_aggregate_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_aggregate.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_add_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_add.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_multiply_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_multiply.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_power_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_power.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_map_prepare_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_map_prepare.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_number_to_words_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_number_to_words.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_aggregate_numbers_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_aggregate_numbers.zip"
  excludes    = ["__pycache__"]
}

data "archive_file" "lambda_word_postprocess_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "build/lambda_word_postprocess.zip"
  excludes    = ["__pycache__"]
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_one" {
  function_name    = "${var.project_name}-lambda-one-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_one.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_one_zip.output_path
  source_code_hash = data.archive_file.lambda_one_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_two" {
  function_name    = "${var.project_name}-lambda-two-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_two.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_two_zip.output_path
  source_code_hash = data.archive_file.lambda_two_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_words" {
  function_name    = "${var.project_name}-lambda-words-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_words.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_words_zip.output_path
  source_code_hash = data.archive_file.lambda_words_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_compute_product" {
  function_name    = "${var.project_name}-lambda-compute-product-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_compute_product.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_compute_product_zip.output_path
  source_code_hash = data.archive_file.lambda_compute_product_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_aggregate" {
  function_name    = "${var.project_name}-lambda-aggregate-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_aggregate.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_aggregate_zip.output_path
  source_code_hash = data.archive_file.lambda_aggregate_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_add" {
  function_name    = "${var.project_name}-lambda-add-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_add.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_add_zip.output_path
  source_code_hash = data.archive_file.lambda_add_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_multiply" {
  function_name    = "${var.project_name}-lambda-multiply-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_multiply.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_multiply_zip.output_path
  source_code_hash = data.archive_file.lambda_multiply_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_power" {
  function_name    = "${var.project_name}-lambda-power-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_power.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_power_zip.output_path
  source_code_hash = data.archive_file.lambda_power_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_map_prepare" {
  function_name    = "${var.project_name}-lambda-map-prepare-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_map_prepare.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_map_prepare_zip.output_path
  source_code_hash = data.archive_file.lambda_map_prepare_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_number_to_words" {
  function_name    = "${var.project_name}-lambda-number-to-words-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_number_to_words.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_number_to_words_zip.output_path
  source_code_hash = data.archive_file.lambda_number_to_words_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_aggregate_numbers" {
  function_name    = "${var.project_name}-lambda-aggregate-numbers-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_aggregate_numbers.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_aggregate_numbers_zip.output_path
  source_code_hash = data.archive_file.lambda_aggregate_numbers_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

resource "aws_lambda_function" "lambda_word_postprocess" {
  function_name    = "${var.project_name}-lambda-word-postprocess-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_word_postprocess.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_word_postprocess_zip.output_path
  source_code_hash = data.archive_file.lambda_word_postprocess_zip.output_base64sha256
  timeout          = 10
  architectures    = ["x86_64"]
  environment { variables = { ENVIRONMENT = var.environment } }
}

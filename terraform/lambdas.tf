locals {
  lambda_source_dir = "../lambdas"
}

# Package lambdas with dependencies (pydantic) into separate zips.
# We use a single null_resource so changes in any source or requirements re-trigger packaging.
resource "null_resource" "package_lambdas" {
  triggers = {
    lambda_one_hash = filesha256("${local.lambda_source_dir}/lambda_one.py")
    lambda_two_hash = filesha256("${local.lambda_source_dir}/lambda_two.py")
    common_hash     = filesha256("${local.lambda_source_dir}/common.py")
    reqs_hash       = filesha256("../requirements-lambda.txt")
  }
  provisioner "local-exec" {
    command = <<EOT
set -e
mkdir -p build
rm -rf build/lambda_one build/lambda_two build/lambda_one.zip build/lambda_two.zip
mkdir -p build/lambda_one build/lambda_two
python3 -m pip install --upgrade pip >/dev/null 2>&1 || true
# Build lambda_one (force fresh deps)
python3 -m pip install --no-cache-dir --force-reinstall -r ../requirements-lambda.txt -t build/lambda_one
rm -rf build/lambda_one/pydantic_core* build/lambda_one/pydantic/__pycache__ || true
cp ${local.lambda_source_dir}/common.py ${local.lambda_source_dir}/lambda_one.py build/lambda_one/
(cd build/lambda_one && zip -r ../lambda_one.zip . >/dev/null)
# Build lambda_two (force fresh deps)
python3 -m pip install --no-cache-dir --force-reinstall -r ../requirements-lambda.txt -t build/lambda_two
rm -rf build/lambda_two/pydantic_core* build/lambda_two/pydantic/__pycache__ || true
cp ${local.lambda_source_dir}/common.py ${local.lambda_source_dir}/lambda_two.py build/lambda_two/
(cd build/lambda_two && zip -r ../lambda_two.zip . >/dev/null)
EOT
  }
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
  filename         = "build/lambda_one.zip"
  source_code_hash = filebase64sha256("build/lambda_one.zip")
  timeout          = 10
  architectures    = ["x86_64"]
  depends_on       = [null_resource.package_lambdas]
  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

resource "aws_lambda_function" "lambda_two" {
  function_name    = "${var.project_name}-lambda-two-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_two.lambda_handler"
  runtime          = "python3.11"
  filename         = "build/lambda_two.zip"
  source_code_hash = filebase64sha256("build/lambda_two.zip")
  timeout          = 10
  architectures    = ["x86_64"]
  depends_on       = [null_resource.package_lambdas]
  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

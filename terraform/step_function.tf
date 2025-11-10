resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-sfn-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-sfn-policy-${var.environment}"
  role = aws_iam_role.step_functions_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"],
        Resource = [
          aws_lambda_function.lambda_one.arn,
          aws_lambda_function.lambda_two.arn
        ]
      }
    ]
  })
}

# State Machine: LambdaOne -> LambdaTwo
# Using the basic Lambda invocation style; output of LambdaOne becomes input to LambdaTwo.
resource "aws_sfn_state_machine" "fastapi_step_function" {
  name     = "fastapi_step_function"
  role_arn = aws_iam_role.step_functions_role.arn
  definition = jsonencode({
    Comment = "FastAPI two-step Lambda workflow",
    StartAt = "LambdaOne",
    States = {
      LambdaOne = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_one.arn,
        Next = "LambdaTwo"
      },
      LambdaTwo = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_two.arn,
        End = true
      }
    }
  })
}

output "state_machine_arn" { value = aws_sfn_state_machine.fastapi_step_function.arn }

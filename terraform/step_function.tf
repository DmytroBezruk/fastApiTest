resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-sfn-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
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

# State Machine: LambdaOne -> Choice -> Pass -> LambdaTwo -> Succeed/Fail (Express type for synchronous execution via StartSyncExecution)
resource "aws_sfn_state_machine" "fastapi_step_function" {
  name     = "fastapi_step_function"
  role_arn = aws_iam_role.step_functions_role.arn
  type     = "EXPRESS"
  definition = jsonencode({
    Comment = "FastAPI two-step Lambda workflow with Choice/Pass/Fail/Succeed",
    StartAt = "LambdaOne",
    States = {
      LambdaOne = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_one.arn,
        Next = "ChoiceAfterFirst"
      },
      ChoiceAfterFirst = {
        Type    = "Choice",
        Choices = [
          {
            Variable      = "$.statusCode",
            NumericEquals = 200,
            Next          = "PassPrep"
          }
        ],
        Default = "FailureState"
      },
      PassPrep = {
        Type       = "Pass",
        Result     = { note = "Passing through before LambdaTwo" },
        ResultPath = "$.pass_info",
        Next       = "LambdaTwo"
      },
      LambdaTwo = {
        Type     = "Task",
        Resource = aws_lambda_function.lambda_two.arn,
        Next     = "SuccessState"
      },
      SuccessState = {
        Type = "Succeed"
      },
      FailureState = {
        Type  = "Fail",
        Error = "LambdaOneFailed",
        Cause = "statusCode not 200"
      }
    }
  })
}

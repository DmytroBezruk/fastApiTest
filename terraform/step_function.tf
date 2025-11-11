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
          aws_lambda_function.lambda_two.arn,
          aws_lambda_function.lambda_words.arn,
          aws_lambda_function.lambda_compute_product.arn,
          aws_lambda_function.lambda_aggregate.arn
        ]
      }
    ]
  })
}

# State Machine: Choice start -> either words path or numeric path
resource "aws_sfn_state_machine" "fastapi_step_function" {
  name     = "fastapi_step_function"
  role_arn = aws_iam_role.step_functions_role.arn
  type     = "EXPRESS"
  definition = jsonencode({
    Comment = "FastAPI workflow with product map branch",
    StartAt = "ValueDecision",
    States = {
      ValueDecision = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.value",
            NumericGreaterThan = 10000,
            Next = "LambdaWords"
          }
        ],
        Default = "ComputeProduct"
      },
      LambdaWords = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_words.arn,
        Next = "SuccessState"
      },
      ComputeProduct = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_compute_product.arn,
        Next = "ProductDecision"
      },
      ProductDecision = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.product", # product now top-level from lambda_compute_product
            NumericGreaterThan = 1000,
            Next = "MapParts"
          }
        ],
        Default = "LambdaOne"
      },
      MapParts = {
        Type = "Map",
        ItemsPath = "$.parts", # parts now top-level
        MaxConcurrency = 5,
        Parameters = {
          "part.$" = "$$.MapItem.Value",
          # Pass each part as both 'value' and keep multiplier 0 so words show number alone
          "value.$" = "$$.MapItem.Value",
          "multiplier" = 0
        },
        Iterator = {
          StartAt = "WordsEachPart",
          States = {
            WordsEachPart = {
              Type = "Task",
              Resource = aws_lambda_function.lambda_words.arn,
              End = true
            }
          }
        },
        ResultPath = "$.mapped_parts",
        Next = "AggregateParts"
      },
      AggregateParts = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_aggregate.arn,
        Parameters = {
          "mapped.$" = "$.mapped_parts"
        },
        Next = "PostAggregateChoice"
      },
      PostAggregateChoice = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.aggregated_total",
            NumericGreaterThan = 5000,
            Next = "SuccessState"
          }
        ],
        Default = "LambdaOne"
      },
      LambdaOne = {
        Type     = "Task",
        Resource = aws_lambda_function.lambda_one.arn,
        Next     = "ChoiceAfterFirst"
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
      SuccessState = { Type = "Succeed" },
      FailureState = { Type = "Fail", Error = "LambdaFlowFailed", Cause = "Non-200 status code" }
    }
  })
}

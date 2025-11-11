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
          aws_lambda_function.lambda_add.arn,
          aws_lambda_function.lambda_multiply.arn,
          aws_lambda_function.lambda_power.arn,
          aws_lambda_function.lambda_map_prepare.arn,
          aws_lambda_function.lambda_number_to_words.arn,
          aws_lambda_function.lambda_aggregate_numbers.arn
        ]
      }
    ]
  })
}

# State Machine: Branching arithmetic workflow: add, multiply, power
resource "aws_sfn_state_machine" "fastapi_step_function" {
  name     = "fastapi_step_function"
  role_arn = aws_iam_role.step_functions_role.arn
  type     = "EXPRESS"
  definition = jsonencode({
    Comment = "Branching arithmetic workflow: add, multiply, power",
    StartAt = "Init",
    States = {
      Init = {
        Type = "Pass",
        # ResultPath = "$.trace",
        # Result = {
        #   steps = {}  # use object map instead of array
        # },
        Next = "BranchChoice"
      },
      BranchChoice = {
        Type = "Choice",
        Choices = [
          { Variable = "$.branch", StringEquals = "one", Next = "AddOp" },
          { Variable = "$.branch", StringEquals = "two", Next = "MultiplyOp" },
          { Variable = "$.branch", StringEquals = "three", Next = "PowerOp" }
        ],
        Default = "FailUnknownBranch"
      },
      AddOp = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_add.arn,
        ResultPath = "$.pre_result",
        Next = "MapPrep"
      },
      MultiplyOp = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_multiply.arn,
        ResultPath = "$.pre_result",
        Next = "MapPrep"
      },
      PowerOp = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_power.arn,
        ResultPath = "$.pre_result",
        Next = "MapPrep"
      },
      MapPrep = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_map_prepare.arn,
        ResultPath = "$.map_prep",
        Next = "NumbersMap"
      },
      NumbersMap = {
        Type = "Map",
        ItemsPath = "$.map_prep.numbers",
        Iterator = {
          StartAt = "NumToWords",
          States = {
            NumToWords = {
              Type = "Task",
              Resource = aws_lambda_function.lambda_number_to_words.arn,
              End = true
            }
          }
        },
        ResultPath = "$.words_items",
        Next = "AggregateNumbers"
      },
      AggregateNumbers = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_aggregate_numbers.arn,
        ResultPath = "$.numbers_summary",
        Next = "SumToWords"
      },
      SumToWords = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_number_to_words.arn,
        Parameters = {
          "value.$": "$.numbers_summary.sum"
        },
        ResultPath = "$.summary_words",
        Next = "RecordOp"
      },
      RecordOp = {
        Type = "Pass",
        # Parameters = {
        #   name = "PowerOp",
        #   input = { "number.$" = "$.number", "factor.$" = "$.factor", "branch.$" = "$.branch" },
        #   output = { "result.$" = "$.power_result.result", "full.$" = "$.power_result" }
        # },
        # ResultPath = "$.trace.steps.PowerOp",
        Next = "Finalize"
      },
      Finalize = {
        Type = "Pass",
        # Parameters = {
        #   summary = {
        #     input = { "number.$" = "$.number", "factor.$" = "$.factor", "branch.$" = "$.branch" },
        #     "trace.$" = "$.trace.steps"
        #   }
        # },
        # ResultPath = "$.final",
        Next = "SuccessState"
      },
      SuccessState = { Type = "Succeed" },
      FailUnknownBranch = { Type = "Fail", Error = "UnknownBranch", Cause = "branch must be one|two|three" }
    }
  })
}

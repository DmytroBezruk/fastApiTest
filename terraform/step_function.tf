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
          aws_lambda_function.lambda_power.arn
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
        ResultPath = "$.trace",
        Result = {
          steps = {}  # use object map instead of array
        },
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
        ResultPath = "$.add_result",
        Next = "RecordAdd"
      },
      RecordAdd = {
        Type = "Pass",
        Parameters = {
          name = "AddOp",
          input = { "number.$" = "$.number", "factor.$" = "$.factor", "branch.$" = "$.branch" },
          output = { "result.$" = "$.add_result.result", "full.$" = "$.add_result" }
        },
        ResultPath = "$.trace.steps.AddOp",
        Next = "Finalize"
      },
      MultiplyOp = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_multiply.arn,
        ResultPath = "$.multiply_result",
        Next = "RecordMultiply"
      },
      RecordMultiply = {
        Type = "Pass",
        Parameters = {
          name = "MultiplyOp",
          input = { "number.$" = "$.number", "factor.$" = "$.factor", "branch.$" = "$.branch" },
          output = { "result.$" = "$.multiply_result.result", "full.$" = "$.multiply_result" }
        },
        ResultPath = "$.trace.steps.MultiplyOp",
        Next = "Finalize"
      },
      PowerOp = {
        Type = "Task",
        Resource = aws_lambda_function.lambda_power.arn,
        ResultPath = "$.power_result",
        Next = "RecordPower"
      },
      RecordPower = {
        Type = "Pass",
        Parameters = {
          name = "PowerOp",
          input = { "number.$" = "$.number", "factor.$" = "$.factor", "branch.$" = "$.branch" },
          output = { "result.$" = "$.power_result.result", "full.$" = "$.power_result" }
        },
        ResultPath = "$.trace.steps.PowerOp",
        Next = "Finalize"
      },
      Finalize = {
        Type = "Pass",
        Parameters = {
          summary = {
            input = { "number.$" = "$.number", "factor.$" = "$.factor", "branch.$" = "$.branch" },
            "trace.$" = "$.trace.steps"
          }
        },
        ResultPath = "$.final",
        Next = "SuccessState"
      },
      SuccessState = { Type = "Succeed" },
      FailUnknownBranch = { Type = "Fail", Error = "UnknownBranch", Cause = "branch must be one|two|three" }
    }
  })
}

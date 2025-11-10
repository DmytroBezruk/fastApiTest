output "lambda_one_arn" { value = aws_lambda_function.lambda_one.arn }
output "lambda_two_arn" { value = aws_lambda_function.lambda_two.arn }
output "state_machine_arn" { value = aws_sfn_state_machine.fastapi_step_function.arn }


variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "create_lambda_one" {
  type    = bool
  default = true
}

variable "create_lambda_two" {
  type    = bool
  default = true
}

variable "create_step_function" {
  type    = bool
  default = true
}
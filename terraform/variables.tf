variable "project_name" {
  type        = string
  description = "Base name for resources"
  default     = "fastapi-test"
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID used to build ARNs"
}

variable "environment" {
  type        = string
  description = "Deployment environment suffix (e.g. dev, prod)"
  default     = "dev"
}

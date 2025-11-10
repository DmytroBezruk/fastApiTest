# Optional remote backend example (S3). Rename to backend.tf and adjust values to enable.
# terraform {
#   backend "s3" {
#     bucket = "your-terraform-state-bucket"
#     key    = "fastapi-test/terraform.tfstate"
#     region = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt = true
#   }
# }


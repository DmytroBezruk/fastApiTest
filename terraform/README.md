# Terraform Infrastructure for FastAPI Step Function

This Terraform configuration provisions:

- Two AWS Lambda functions (lambda_one, lambda_two) from the `lambdas/` folder
- IAM role for the Lambdas with basic execution permissions
- IAM role + policy for AWS Step Functions to invoke the Lambdas
- A Step Functions State Machine that runs lambda_one then lambda_two

## Prerequisites
- Terraform >= 1.5
- AWS credentials exported (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` optional) or configured via profile.
- Python dependencies (none external right now; if you add dependencies you must package them).

## Directory Layout
```
terraform/
  provider.tf
  variables.tf
  lambdas.tf
  step_function.tf
  outputs.tf
```

## Usage
From inside `terraform/` directory:

```bash
terraform init
terraform plan -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev
terraform apply -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev -auto-approve
```

After apply, note the `state_machine_arn` output. Put that ARN in your `.env` as:
```
AWS_ACCOUNT_ID=YOUR_ACCOUNT_ID
AWS_REGION=us-east-1
```
The FastAPI code constructs the full ARN using `AWS_ACCOUNT_ID`.

## Updating Lambdas
Change code under `lambdas/` then rerun:
```bash
terraform apply -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev -auto-approve
```
Terraform will repackage zips and update functions.

## Adding Dependencies
If Lambda code requires third-party packages:
1. Create a `requirements-lambda.txt` listing packages.
2. Replace `data "archive_file"` with an external packaging step (e.g., a script to build a deployment folder including site-packages) or use Terraform `null_resource` + local build.

## Destroy
```bash
terraform destroy -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev -auto-approve
```

## Next Steps
- Add CloudWatch log retention
- Add error handling and retries in the State Machine definition
- Add API Gateway to trigger the first Lambda directly


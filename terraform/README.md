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

## Dependency Packaging for Lambdas
We now bundle Python dependencies (e.g., pydantic) into each Lambda zip using a `null_resource` in `lambdas.tf` and the file `requirements-lambda.txt` at project root.

How it works:
- Terraform calculates a hash of each lambda source file and `requirements-lambda.txt`.
- On any change, it re-runs a local packaging script which:
  - Creates `build/lambda_one.zip` and `build/lambda_two.zip` with dependencies + source files.
- Lambda resources reference those zip files directly.

To force rebuild (e.g., if something seems cached):
```bash
terraform taint null_resource.package_lambdas
terraform apply -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev -auto-approve
```

Add a new dependency:
1. Edit `requirements-lambda.txt`.
2. Apply again (`terraform apply ...`).

Note: For compiled dependencies ensure you package on an x86_64 Linux environment matching AWS Lambda (Amazon Linux). Pure Python libs like pydantic are fine from most environments.

## Destroy
```bash
terraform destroy -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev -auto-approve
```

## Handling Existing IAM Roles (409 EntityAlreadyExists)
If you previously created the IAM roles manually (or from an earlier failed apply), Terraform will fail with:
```
EntityAlreadyExists: Role with name fastapi-test-lambda-role-dev already exists
```
You have two options:

### Option 1: Import existing roles into Terraform state
Run inside `terraform/` directory (adjust names if you changed environment):
```bash
terraform init
terraform import aws_iam_role.lambda_role fastapi-test-lambda-role-dev
terraform import aws_iam_role.step_functions_role fastapi-test-sfn-role-dev
```
Then rerun:
```bash
terraform apply -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev
```
Terraform will then manage those roles.

### Option 2: Delete roles manually and re-apply
Detach policies first, then delete roles:
```bash
aws iam detach-role-policy \
  --role-name fastapi-test-lambda-role-dev \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name fastapi-test-lambda-role-dev

aws iam detach-role-policy \
  --role-name fastapi-test-sfn-role-dev \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess || true
aws iam delete-role --role-name fastapi-test-sfn-role-dev
```
(Adjust policies if different.) Then:
```bash
terraform apply -var aws_account_id=YOUR_ACCOUNT_ID -var environment=dev
```

### Option 3: Change role names
Add a suffix by editing `lambdas.tf` and `step_function.tf` resource names:
```hcl
name = "${var.project_name}-lambda-role-${var.environment}-v2"
```
But prefer import to avoid orphaned roles.

## Recommended
Use Option 1 (import) to keep existing ARNs stable.

## Next Steps
- Add CloudWatch log retention
- Add error handling and retries in the State Machine definition
- Add API Gateway to trigger the first Lambda directly

## New Conditional Start (ValueDecision)
The state machine now begins with a Choice state:
- If `$.value > 10000` it invokes `lambda_words` which returns both numeric and English words for the final result (`value + multiplier`).
- Otherwise it follows the original numeric path: lambda_one -> pass -> lambda_two.

Lambda outputs:
- `lambda_words`: `{ final_result, final_result_words }` (body JSON inside `statusCode` wrapper)
- Regular path ends with `lambda_two` producing `{ final_result }`

To test the words branch:
```bash
curl -X POST http://localhost:$HTTP_BIND/run-step-function \
  -H 'Content-Type: application/json' \
  -d '{"value": 20001, "multiplier": 3}'
```
Expect `final_result_words` in the output

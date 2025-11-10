#!/bin/bash
set -e

echo "🔍 Checking AWS resources..."

# Check individual resources
LAMBDA_ONE_EXISTS=$(aws lambda get-function --function-name lambda_one >/dev/null 2>&1 && echo "yes" || echo "no")
LAMBDA_TWO_EXISTS=$(aws lambda get-function --function-name lambda_two >/dev/null 2>&1 && echo "yes" || echo "no")
STEP_FUNCTION_EXISTS=$(aws stepfunctions describe-state-machine --state-machine-arn arn:aws:states:${AWS_REGION}:${AWS_ACCOUNT_ID}:stateMachine:fastapi_step_function >/dev/null 2>&1 && echo "yes" || echo "no")

echo "Current status:"
echo "  Lambda One: $LAMBDA_ONE_EXISTS"
echo "  Lambda Two: $LAMBDA_TWO_EXISTS"
echo "  Step Function: $STEP_FUNCTION_EXISTS"

# Create a terraform.tfvars file with the appropriate values
cat > terraform/terraform.tfvars << EOF
create_lambda_one = $( [[ "$LAMBDA_ONE_EXISTS" == "no" ]] && echo true || echo false )
create_lambda_two = $( [[ "$LAMBDA_TWO_EXISTS" == "no" ]] && echo true || echo false )
create_step_function = $( [[ "$STEP_FUNCTION_EXISTS" == "no" ]] && echo true || echo false )
EOF

echo "Generated terraform.tfvars:"
cat terraform/terraform.tfvars

# Check if any creation is needed
if [[ "$LAMBDA_ONE_EXISTS" = "no" ]] || [[ "$LAMBDA_TWO_EXISTS" = "no" ]] || [[ "$STEP_FUNCTION_EXISTS" = "no" ]]; then
    echo "🚀 Missing AWS resources detected. Running Terraform..."
    cd terraform
    terraform init -input=false
    terraform apply -auto-approve -input=false
    cd ..
else
    echo "✅ All AWS resources already exist. Skipping Terraform."
fi

echo "▶️ Starting FastAPI..."
python server.py
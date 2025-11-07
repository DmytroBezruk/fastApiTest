# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

# --- Environment setup ---
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

ENV AWS_DEFAULT_REGION=${AWS_REGION:-us-east-1}

# --- Install system dependencies + AWS CLI + Terraform ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential zip curl unzip jq groff less \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI via pip (compatible with both ARM and x86)
RUN pip install --no-cache-dir awscli

# Install Terraform
ARG TERRAFORM_VERSION=1.9.2
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    -o terraform.zip \
    && unzip terraform.zip -d /usr/local/bin \
    && rm terraform.zip

# --- Install Python dependencies ---
RUN pip install --no-cache-dir pipenv

WORKDIR /app

COPY Pipfile ./
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --system --skip-lock --clear

# --- Copy project ---
COPY . .

# --- Build Lambda packages ---
RUN mkdir -p build \
    && cd lambdas \
    && zip -r ../build/lambda_one.zip lambda_one.py common.py __init__.py \
    && zip -r ../build/lambda_two.zip lambda_two.py common.py __init__.py \
    && cd ..

# --- Default CMD ---
# Checks if Lambda and Step Function exist before Terraform apply
CMD bash -c '\
set -e; \
echo "🔍 Checking AWS resources..."; \
if aws lambda get-function --function-name lambda_one >/dev/null 2>&1 && \
   aws stepfunctions describe-state-machine --state-machine-arn arn:aws:states:${AWS_REGION}:${AWS_ACCOUNT_ID}:stateMachine:fastapi_step_function >/dev/null 2>&1; then \
    echo "✅ Lambda & Step Function already exist. Skipping Terraform."; \
else \
    echo "🚀 Missing AWS resources. Running Terraform..."; \
    cd terraform && terraform init -input=false && terraform apply -auto-approve -input=false; \
fi; \
echo "▶️ Starting FastAPI..."; \
python server.py'

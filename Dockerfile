# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

# --- System dependencies ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential zip curl unzip \
    && rm -rf /var/lib/apt/lists/*

# --- Install Terraform ---
ARG TERRAFORM_VERSION=1.9.2
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    -o terraform.zip \
    && unzip terraform.zip -d /usr/local/bin \
    && rm terraform.zip

# --- Install pipenv ---
RUN pip install --no-cache-dir pipenv

WORKDIR /app

# --- Copy dependency manifests ---
COPY Pipfile ./
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --system --skip-lock --clear

# --- Copy all code ---
COPY . .

# --- Build Lambda packages ---
RUN mkdir -p build \
    && cd lambdas \
    && zip -r ../build/lambda_one.zip lambda_one.py common.py __init__.py \
    && zip -r ../build/lambda_two.zip lambda_two.py common.py __init__.py \
    && cd ..

# --- Environment variables ---
ENV ENVIRONMENT=local

ENV AWS_REGION=${AWS_REGION}
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

# --- Default CMD ---
# Terraform will use AWS credentials from .env at runtime, then start FastAPI
CMD cd terraform && terraform init -input=false && terraform apply -auto-approve -input=false && cd /app && python server.py

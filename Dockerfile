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

COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# Use the startup script
CMD ["/app/startup.sh"]

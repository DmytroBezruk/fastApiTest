# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

# Install system deps (if needed for uvloop)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*

# Install pipenv
RUN pip install --no-cache-dir pipenv

WORKDIR /app

# Copy dependency manifests first for better layer caching
COPY Pipfile ./
# Optional: if you later add a Pipfile.lock it'll speed reproducibility
# COPY Pipfile.lock ./

# Install prod dependencies into system site-packages (no virtualenv)
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --system --skip-lock --clear

# Copy application code
COPY . .

# Do not hardcode port here; compose handles mapping using HTTP_BIND env var (port-only).
# EXPOSE omitted intentionally to avoid duplicating the port configuration.

# Default environment; override via compose env_file
ENV ENVIRONMENT=local

CMD ["python", "server.py"]

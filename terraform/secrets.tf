resource "aws_secretsmanager_secret" "app_config" {
  name        = "${var.project_name}-app-config-${var.environment}"
  description = "Application shared config secret for lambdas and API"
}

# Initial version (demo only) storing JSON string; rotate in production.
resource "aws_secretsmanager_secret_version" "app_config_version" {
  secret_id     = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    sample_api_key = "demo-12345",
    external_token = "token-abc",
    feature_flag   = true
  })
}

output "app_config_secret_arn" {
  value = aws_secretsmanager_secret.app_config.arn
}


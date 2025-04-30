
# Create the secret container
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = var.db_secret_name
  description = "Database credentials for registration app"
}

# Add the JSON-formatted secret value
resource "aws_secretsmanager_secret_version" "db_credentials_value" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    DB_HOST = var.db_host
    DB_USER = var.db_user
    DB_PASS = var.db_pass
    DB_NAME = var.db_name
  })
  # lifecycle {
  #   prevent_destroy = true
  # }
}

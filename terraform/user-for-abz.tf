# Створення IAM користувача
resource "aws_iam_user" "readonly_user" {
  name = "mark2"
}

# Прикріплення політики до користувача
resource "aws_iam_user_policy_attachment" "readonly_attachment" {
  user       = aws_iam_user.readonly_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Генерація випадкового пароля для користувача
resource "random_password" "readonly_user_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Збереження пароля в AWS Secrets Manager
resource "aws_secretsmanager_secret" "readonly_user_password_secret" {
  name = "readonly-user-password-secret"

  tags = {
    Environment = "ABZ"
  }
}

resource "aws_secretsmanager_secret_version" "readonly_user_password_version" {
  secret_id     = aws_secretsmanager_secret.readonly_user_password_secret.id
  secret_string = jsonencode({
    username = aws_iam_user.readonly_user.name
    password = random_password.readonly_user_password.result
  })
}

# Налаштування пароля для користувача IAM
resource "aws_iam_user_login_profile" "readonly_user_login" {
  user                      = aws_iam_user.readonly_user.name
  password_reset_required   = false
}
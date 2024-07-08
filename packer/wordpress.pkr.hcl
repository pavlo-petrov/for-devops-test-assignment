variable "aws_region" {
  type = string
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "admin_subnet_ids" {
  type = string
}

variable "rds_endpoint" {
  type = string
}

variable "redis_endpoint" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "timestamp" {
  type = string
  default = ""
}

variable "ami_name" {
  type = string
  default = ""
}

variable "security_group_for_parcker" {
  type = string
}

variable "DOCKER_HUB_ACCESS_TOKEN" {
  type = string
}
variable "DOCKER_HUB_USERNAME" {
  type = string
}

variable "wordpress_db_passwd" {
  type = string
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "wordpress" {
  ami_name      = "${var.ami_name}-${var.timestamp}"
  instance_type = "t2.micro"
  region        = var.aws_region
  vpc_id        = var.vpc_id
  subnet_id     = var.admin_subnet_ids
  security_group_id = var.security_group_for_parcker
  source_ami_filter {
    filters = {
      architecture        = "x86_64"
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}


build {
  sources = ["source.amazon-ebs.wordpress"]

provisioner "shell" {
  inline = [
    "sudo apt clean",
    "sudo rm -rf /var/lib/apt/lists/*",
    "sudo apt update -y",
    "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg",
    "sudo install -m 0755 -d /etc/apt/keyrings",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
    "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
    "echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
    "sudo DEBIAN_FRONTEND=noninteractive apt update -y",
    "sudo DEBIAN_FRONTEND=noninteractive apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
    "sudo apt update -y",
    "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
    "sudo usermod -aG docker $USER",
    "newgrp docker",
    "sudo systemctl start docker",
    "sudo systemctl enable docker",
    "echo $DOCKER_HUB_ACCESS_TOKEN | sudo docker login -u $DOCKER_HUB_USERNAME --password-stdin",
    "sudo docker pull footballaws2/wordpress:latest",
    "sudo docker run -d -p 80:80 --restart always --name my-container --memory 500m footballaws2/wordpress:latest",
    "sudo rm /root/.docker/config.json",
    "DB_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"SHOW DATABASES LIKE '${DB_NAME}';\" | grep \"${DB_NAME}\")",
    "if [ -z \"$DB_EXISTS\" ]; then",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"CREATE DATABASE ${DB_NAME};\"",
    "else",
    "echo \"База даних ${DB_NAME} вже існує.\"",
    "fi",
    "USER_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"SELECT 1 FROM mysql.user WHERE user = '${DB_USER}' AND host = '${DB_HOST}';\" | grep \"1\")",
    "if [ -z \"$USER_EXISTS\" ]; then",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';\"",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';\"",
    "else",
    "echo \"Користувач ${DB_USER}@${DB_HOST} вже існує.\"",
    "fi",
    "",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"FLUSH PRIVILEGES;\"",
    "cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wp-config.php",
    "sudo sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php",
    "sudo sed -i "s/username_here/${DB_USER}/" /var/www/html/wp-config.php",
    "sudo sed -i "s/password_here/${DB_PASSWORD}/" /var/www/html/wp-config.php",
    "sudo sed -i "s/localhost/${DB_HOST}/" /var/www/html/wp-config.php",
    "DB_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"SHOW DATABASES LIKE '${DB_NAME}';\" | grep \"${DB_NAME}\")",
    "if [ -z \"$DB_EXISTS\" ]; then",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"CREATE DATABASE ${DB_NAME};\"",
    "else",
    "echo \"База даних ${DB_NAME} вже існує.\"",
    "fi",
    "",
    "USER_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"SELECT 1 FROM mysql.user WHERE user = '${DB_USER}' AND host = '${DB_HOST}';\" | grep \"1\")",
    "if [ -z \"$USER_EXISTS\" ]; then",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';\"",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';\"",
    "else",
    "echo \"Користувач ${DB_USER}@${DB_HOST} вже існує.\"",
    "fi",
    "",
    "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e \"FLUSH PRIVILEGES;\"",
    "",
    "sudo -u www-data php -r \"",
    "\\$mysqli = new mysqli('${DB_HOST}', '${DB_USER}', '${DB_PASSWORD}', '${DB_NAME}');",
    "if (\\$mysqli->connect_error) {",
    "die('Connection failed: ' . \\\$mysqli->connect_error);",
    "} else {",
    "echo 'Connection successful to database server.';",
    "}",
    "if (!\\$mysqli->select_db('${DB_NAME}')) {",
    "die('Cannot select database: ' . \\\$mysqli->error);",
    "} else {",
    "echo 'Database ${DB_NAME} selected successfully.';",
    "}\"",
    "",
    "# Налаштування Apache",
    "sudo a2enmod rewrite",
    "sudo service apache2 restart",
    "",
    "# Автоматичне встановлення WordPress через WP-CLI",
    "cd /var/www/html/wordpress/",
    "wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar",
    "chmod +x wp-cli.phar",
    "sudo mv wp-cli.phar /usr/local/bin/wp",
    "",
    "if sudo -u www-data wp core is-installed --path=/var/www/html/wordpress/; then",
    "echo \"WordPress вже встановлений. Пропускаємо установку.\"",
    "else",
    "# Виконання установки WordPress",
    "sudo -u www-data wp core install --url=\"${WP_URL}\" --title=\"${WP_TITLE}\" --admin_user=\"${WP_ADMIN_USER}\" --admin_password=\"${WP_ADMIN_PASSWORD}\" --admin_email=\"${WP_ADMIN_EMAIL}\" --path=/var/www/html/wordpress",
    "echo \"WordPress успішно встановлено!\"",
    "fi"
  ]

  environment_vars = [
      "DOCKER_HUB_USERNAME=${var.DOCKER_HUB_USERNAME}",
      "DOCKER_HUB_ACCESS_TOKEN=${var.DOCKER_HUB_ACCESS_TOKEN}"
      "DB_HOST=${var.rds_endpoint}",
      "DB_USER=admin",
      "DB_PASSWORD=${}",
      "DB_NAME=wordpress_db",
      "WP_URL=wordpress-for-test.pp.ua",
      "WP_TITLE=This_is_name_of_Web_site",
      "WP_ADMIN_USER=admin",
      "WP_ADMIN_PASSWORD=${}",
      "WP_ADMIN_EMAIL=some@email.in.ua"
  ]

}
}
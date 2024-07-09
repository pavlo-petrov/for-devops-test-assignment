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
    "sudo rm /root/.docker/config.json",
    "sudo docker run -d -p 80:80 --restart always --name my-container --memory 500m footballaws2/wordpress:latest",
    "docker exec my-container /bin/bash -c \
      DB_HOST='$DB_HOST' \
      DB_USER='$DB_USER' \
      DB_PASSWORD='$DB_PASSWORD' \
      DB_NAME='$DB_NAME' \
      WP_URL='$WP_URL' \
      WP_TITLE='$WP_TITLE' \
      WP_ADMIN_USER='$WP_ADMIN_USER' \
      WP_ADMIN_PASSWORD='$WP_ADMIN_PASSWORD' \
      WP_ADMIN_EMAIL='$WP_ADMIN_EMAIL' \
      /var/www/html/install_wordpress.sh"
  ]

  environment_vars = [
      "DOCKER_HUB_USERNAME=${var.DOCKER_HUB_USERNAME}",
      "DOCKER_HUB_ACCESS_TOKEN=${var.DOCKER_HUB_ACCESS_TOKEN}"
  ]

}

provisioner "shell" {
  script = "./packer/script/install_wordpress.sh"
  pause_before = "10s"
  environment_vars = [
    "DB_HOST=${var.rds_endpoint}",
    "DB_USER=admin",
    "DB_PASSWORD=${var.wordpress_db_passwd}",
    "DB_NAME=wordpress_db",
    "WP_URL=wordpress-for-test.pp.ua",
    "WP_TITLE=This_is_name_of_Web_site",
    "WP_ADMIN_USER=admin",
    "WP_ADMIN_PASSWORD=${var.wordpress_db_passwd}",
    "WP_ADMIN_EMAIL=admin@wordpress-for-test.pp.ua"
  ]
}
}
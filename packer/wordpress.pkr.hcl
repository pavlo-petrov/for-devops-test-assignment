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
    "sudo DEBIAN_FRONTEND=noninteractive apt-get update -y",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
    "sudo apt update -y",
    "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
    "sudo usermod -aG docker $USER",
    "newgrp docker",
    "sudo systemctl start docker",
    "sudo systemctl enable docker",
    "sudo apt install awscli",
    "sudo DOCKER_HUB_USERNAME=$(aws secretsmanager get-secret-value --secret-id prod/wordpress --query SecretString --output text | jq -r '.DOCKER_HUB_USERNAME')",
    "sudo DOCKER_HUB_ACCESS_TOKEN=$(aws secretsmanager get-secret-value --secret-id prod/wordpress --query SecretString --output text | jq -r '.DOCKER_HUB_ACCESS_TOKEN')",
    "echo $DOCKER_HUB_ACCESS_TOKEN | sudo docker login -u $DOCKER_HUB_USERNAME --password-stdin",
    "sudo docker pull footballaws2/wordpress:latest",
    "sudo docker run -d -p 80:80 --restart always --name my-container --memory 500m footballaws2/wordpress:latest"
  ]

}
}
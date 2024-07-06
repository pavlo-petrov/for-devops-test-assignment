variable "aws_region" {}
variable "docker_hub_username" {}
variable "docker_hub_access_token" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
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
  type    = string
  default = "wordpress-prod"
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "frontend" {
  ami_name      = "${var.ami_name}-${var.timestamp}"
  instance_type = "t2.micro"
  region        = var.aws_region
  vpc_id        = var.vpc_id
  subnet_id     = var.admin_subnet_ids
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
  sources = ["source.amazon-ebs.frontend"]

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
    "echo start_DOCKER_HUB",
    "echo $DOCKER_HUB_ACCESS_TOKEN | sudo docker login -u $DOCKER_HUB_USERNAME --password-stdin",
    "sudo docker pull footballaws2/wordpress:latest",
    "sudo docker run -d -p 80:80 --restart always --name my-container --memory 500m footballaws2/wordpress:latest"
  ]
  environment_vars = [
      "DOCKER_HUB_USERNAME=${var.docker_hub_username}",
      "DOCKER_HUB_ACCESS_TOKEN=${var.docker_hub_access_token}"
  ]

}
}
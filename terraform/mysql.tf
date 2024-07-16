variable "db_name" {
  description = "The name of the database to be created"
  type        = string
  default     = "wordpress_25"
}

variable "user_mark" {
  description = "The name of the first user"
  default     = "mark"
}

variable "user_paul" {
  description = "The name of the second user"
  default     = "paul"
}


variable "aws_secret_name" {
  description = "The name of the AWS Secret Manager secret"
  default     = "test_mysql_pass"
}

variable "aws_secret_key" {
  description = "The key of the password in the AWS Secret Manager secret"
  default     = "password_for_mysql"
}


locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.example.secret_string)["password_for_mysql"]
}

resource "aws_instance" "mysql_access" {
  ami             = "ami-0c38b837cd80f13bb"  # AMI для Ubuntu 20.04
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.admin_subnet[0].id
  vpc_security_group_ids = [aws_security_group.db.id, aws_security_group.ssh_access.id]
  key_name      = "eu-west-1"


  tags = {
    Name = "MySQL-Access-Instance"
  }
}

locals {
  db_endpoint_host = split(":", aws_db_instance.default.endpoint)[0]
}

resource "null_resource" "provision_mysql" {
  depends_on = [aws_instance.mysql_access]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.mysql_access.public_ip
      user        = "ubuntu"
      private_key = file("~/Downloads/eu-west-1.pem")
    }

    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y mysql-client",
      "echo [client] > ~/my.cng",
      "echo user=${var.db_username} >> ~/my.cng",
      "echo password=${local.db_password} >> ~/my.cng",
      "echo host=${local.db_endpoint_host} >> ~/my.cng",
      "mysql --defaults-extra-file=~/my.cng -e 'CREATE DATABASE IF NOT EXISTS ${var.db_name};'",
      "echo line1 > ~/my.test",
      "mysql --defaults-extra-file=~/my.cng -e \"CREATE USER '${var.user_mark}'@'%' IDENTIFIED BY '${local.db_password}'; GRANT ALL PRIVILEGES ON ${var.db_name}.* TO '${var.user_mark}'@'%';\"",
      "echo line2 >> ~/my.test",
      "mysql --defaults-extra-file=~/my.cng -e \"CREATE USER '${var.user_paul}'@'%' IDENTIFIED BY '${local.db_password}'; GRANT ALL PRIVILEGES ON ${var.db_name}.* TO '${var.user_paul}'@'%';\"",
      "echo line3 >> ~/my.test"
    ]
  }
}

resource "aws_security_group" "ssh_access" {
  name        = "ssh_access"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id  # Замість aws_vpc.main.id використайте ID вашої VPC

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Це дозволяє доступ з будь-якої IP-адреси. Для більшої безпеки можна вказати конкретні IP-адреси
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
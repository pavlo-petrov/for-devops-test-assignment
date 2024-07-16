########################## main ##########################
provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "mybucketfortest-2024-07-04-test"
    key            = "wordpress/prod/terraform.tfstate"
    region         = "eu-west-1"
  }
}

########################## VPC and SubNets ##########################
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public_subnet" {
  count      = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
 tags = {
   Name = "Public work Subnet ${count.index + 1}"
 }
}

resource "aws_subnet" "admin_subnet" {
  count     = length(var.admin_subnet_cidrs) 
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.admin_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = "true"

tags = {
  Name = "Public admin Subnet ${count.index + 1}"
 }
}

resource "aws_subnet" "database_subnet" {
  count = length(var.databases_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.databases_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

tags = {
  Name = "private database Subnet ${count.index + 1}"
 }
}  

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id

 tags = {
   Name = "VPC Internet Gateway"
 }
}

resource "aws_route_table" "route_table_default" {
 vpc_id = aws_vpc.main.id

 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id

 }
}

resource "aws_route_table_association" "public_subnet_association" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.route_table_default.id
}

resource "aws_route_table_association" "admin_subnet_association" {
  count          = length(aws_subnet.admin_subnet)
  subnet_id      = aws_subnet.admin_subnet[count.index].id
  route_table_id = aws_route_table.route_table_default.id
}


##########################  RDS MySQL and Elastic cashe REDIS ##########################

# DB Subnet Group
resource "aws_db_subnet_group" "default_db" {
  name       = "my-db-subnet-group-1"
  subnet_ids = [for subnet in aws_subnet.database_subnet[*] : subnet.id]

  depends_on = [
    aws_subnet.database_subnet
  ]

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_security_group" "db" {
  name        = var.db_security_group_name
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id # замініть на ваш VPC ID

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "default" {
  identifier              = var.db_instance_identifier
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 30  # autoscailing до 30 Гб
  storage_type            = "gp2"
  username                = var.db_username
  password                = jsondecode(data.aws_secretsmanager_secret_version.example.secret_string)["password_for_mysql"] 
  db_subnet_group_name    = aws_db_subnet_group.default_db.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  availability_zone       = var.db_rds_avail_zone[0]
  port                    = 3306
  multi_az                = false
  auto_minor_version_upgrade = true
  backup_retention_period = 0  # Вимкнути backup
  skip_final_snapshot     = true  # Вимкнути snapshot при видаленні
  deletion_protection     = false  # Вимкнути захист від видалення
  publicly_accessible     = false
  storage_encrypted       = true  # Увімкнути шифрування

  iam_database_authentication_enabled = true  # IAM database authentication

  monitoring_interval     = 0  # Вимкнути Enhanced Monitoring

  depends_on = [
    aws_db_subnet_group.default_db
  ]

  # lifecycle {
  #   prevent_destroy = true
  #   ignore_changes  = [
  #     allocated_storage,
  #     instance_class,
  #     parameter_group_name,
  #   ]
  # }

  tags = {
    Name = "MySQL-Database"
  }
}


data "aws_secretsmanager_secret" "example" {
  name = var.secret_manager_secret_name
}

data "aws_secretsmanager_secret_version" "example" {
  secret_id = data.aws_secretsmanager_secret.example.id
}

########################## Elastic Cashe Redis ##########################

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [for subnet in aws_subnet.database_subnet[*] : subnet.id]
}


resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "my-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.db.id]
  # lifecycle {
  #   prevent_destroy = true
  #   ignore_changes  = [
  #     node_type,
  #     number_cache_clusters,
  #     parameter_group_name,
  #     engine_version,
  # ]
  #}
}

########################## security group for packer ##########################
resource "aws_security_group" "packer_security_group" {
  name        = "packer_security_group"
  description = "Security group for packer deployment"
  vpc_id      = aws_vpc.main.id 

  // Визначте вихідні правила для трафіку
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################## ELB + ASG ##########################

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  admin_subnet_ids = concat(
    aws_subnet.admin_subnet[*].id
  )
}

locals {
  public_subnet_ids = concat(
    aws_subnet.public_subnet[*].id
  )
}

resource "aws_lb" "admin_alb" {
  name               = "load-balancer-admin"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.admin_subnet_ids
}

# resource "aws_lb" "public_alb" {
#   name               = "load-balancer-public"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = local.public_subnet_ids
# }

resource "aws_lb_listener" "http_admin" {
  load_balancer_arn = aws_lb.admin_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_admin" {
  load_balancer_arn = aws_lb.admin_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_arn_path

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg2.arn
  }
}


# resource "aws_lb_listener" "http_public" {
#   load_balancer_arn = aws_lb.public_alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# resource "aws_lb_listener" "https_public" {
#   load_balancer_arn = aws_lb.public_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.ssl_arn_path

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.asg2.arn
#   }
# }



resource "aws_lb_target_group" "asg1" {
  name        = "asg1-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  stickiness {
    type                = "lb_cookie"
    cookie_duration     = 3600  # 1 day
    enabled             = true
  }
}

resource "aws_lb_target_group" "asg2" {
  name        = "asg2-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "wpadmin_rule" {
  listener_arn = aws_lb_listener.https_admin.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg1.arn
  }

  condition {
    host_header {
      values = [var.hosted_zone_name]
    }
  }

  condition {
    path_pattern {
      values = ["/wp-admin/*"]
    }
  }
}

resource "aws_lb_listener_rule" "default_rule" {
  listener_arn = aws_lb_listener.https_admin.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg2.arn
  }

  condition {
    host_header {
      values = [var.hosted_zone_name]
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}


# resource "aws_lb_listener_rule" "default_rule" {
#   listener_arn = aws_lb_listener.https_public.arn
#   priority     = 200

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.asg2.arn
#   }

#   condition {
#     host_header {
#       values = [ var.hosted_zone_name ]
#     }
#   }
# }

resource "aws_launch_template" "wordpress_admin" {
  name          = "wordpress-launch-template-admin"
  image_id      = "ami-0c38b837cd80f13bb" # змініть на свій AMI
  instance_type = "t2.micro"
  key_name      = "eu-west-1" # Змініть на свій ключ SSH

  network_interfaces {
    security_groups             = [aws_security_group.instance_sg.id]
    associate_public_ip_address = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wordpress-admin"
    }
  }
}

resource "aws_launch_template" "wordpress_public" {
  name          = "wordpress-launch-template-public"
  image_id      = "ami-0c38b837cd80f13bb"
  instance_type = "t2.micro"
  key_name      = "eu-west-1"

  network_interfaces {
    security_groups             = [aws_security_group.instance_sg.id]
    associate_public_ip_address = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wordpress-public"
    }
  }
}

resource "aws_autoscaling_group" "asg1" {
  launch_template {
    id = aws_launch_template.wordpress_admin.id
    version = "$Latest"
  } 
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  vpc_zone_identifier  = local.admin_subnet_ids

  tag {
    key                 = "Name"
    value               = "asg1-instance"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.asg1.arn]

  health_check_type         = "EC2"
  health_check_grace_period = 300
}

resource "aws_autoscaling_group" "asg2" {
  launch_template {
    id = aws_launch_template.wordpress_public.id
    version = "$Latest"
  } 
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = local.public_subnet_ids

  tag {
    key                 = "Name"
    value               = "asg2-instance"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.asg1.arn]

  health_check_type         = "EC2"
  health_check_grace_period = 300
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id  
  name    = "wordpress-for-test.pp.ua"
  type    = "A"

  alias {
    name                   = aws_lb.admin_alb.dns_name
    zone_id                = aws_lb.admin_alb.zone_id
    evaluate_target_health = true
  }
}

data "aws_route53_zone" "selected" {
  name = var.hosted_zone_name
}

############# S3 bucket for wp offline files ########### 

# Створення S3 бакету
resource "aws_s3_bucket" "wordpress_bucket" {
  bucket = var.s3_bucket_for_wordpress_name
  acl    = "private"
}

# Політика для доступу користувачів до S3 бакету
data "aws_iam_policy_document" "user_access_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = ["${aws_s3_bucket.wordpress_bucket.arn}/*", "${aws_s3_bucket.wordpress_bucket.arn}"]
  }
}

resource "aws_iam_policy" "user_access_policy" {
  name        = "WordpressUserAccessPolicy"
  description = "Access policy for users to read from the Wordpress S3 bucket"
  policy      = data.aws_iam_policy_document.user_access_policy.json
}

# Створення групи та додавання політики до групи
resource "aws_iam_group" "wordpress_users_group" {
  name = "WordpressUsersGroup"
}

resource "aws_iam_group_policy_attachment" "attach_user_policy" {
  group      = aws_iam_group.wordpress_users_group.name
  policy_arn = aws_iam_policy.user_access_policy.arn
}

# Політика для доступу серверів до S3 бакету
data "aws_iam_policy_document" "ec2_access_policy" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = ["${aws_s3_bucket.wordpress_bucket.arn}/*", "${aws_s3_bucket.wordpress_bucket.arn}"]
  }
}

resource "aws_iam_policy" "ec2_access_policy" {
  name        = "WordpressEC2AccessPolicy"
  description = "Access policy for EC2 instances to read and write to the Wordpress S3 bucket"
  policy      = data.aws_iam_policy_document.ec2_access_policy.json
}

# Створення IAM ролі для EC2 інстансів
resource "aws_iam_role" "ec2_role" {
  name = "WordpressEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Прив'язка політики до ролі
resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_access_policy.arn
}

# Профіль інстансу для використання IAM ролі
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "WordpressEC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# # Приклад EC2 інстансу з прив'язкою до IAM профілю
# resource "aws_instance" "wordpress_instance" {
#   ami           = "ami-12345678"
#   instance_type = "t2.micro"

#   iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

#   # Інші налаштування EC2 інстансу
#   subnet_id = "subnet-abcdef1234567890"
# }
############################ create DataBase and user #######################

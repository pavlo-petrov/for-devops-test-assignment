############## Region ##############
variable "aws_region" {
    type = string
    default = "eu-west-1"
}

############## vpc ###############
variable "vpc_cidr_block" {
    type = string
    default = "10.0.0.0/16"
}

variable "aws_account_id" {
  type    = string
  default = "975050270418"
}

############## subnets ###############
# for WP work's VMs
variable "public_subnet_cidrs" {
    type        = list(string)
    description = "Public work Subnet CIDR values"
    default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# for WP admin VMs
variable "admin_subnet_cidrs" {
    type        = list(string)
    description = "Public admin Subnet CIDR value"
    default     = [ "10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24" ]
}

# for databases 
variable "databases_subnet_cidrs" {
    type        = list(string)
    description = "Public databases Subnet CIDR value"
    default     = [ "10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"  ]
##################### if we use not FREE TIER AWS - we can create more than one database ...    
}

# for availoble zones
variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
} 

# MySQL
variable "db_instance_identifier" {
  default = "my-mysql-db"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "your_password_here"  # Замість цього використовуйте AWS Secrets Manager
}

variable "db_subnet_group_name" {
  default = "db_wordpress_subnet_group"
}

variable "db_security_group_name" {
  default = "db_sqk_sg"
}

variable "db_subnet_id" {
  type    = list(string)
  default = [ "db_rds_subnet" ]
}

variable "db_rds_avail_zone" {
  type    = list(string)
  default = [ "eu-west-1a" ]
}

variable "secret_manager_secret_name" {
  type    = string
  default = "test_mysql_pass"
}

variable "ssl_arn_path" {
  type = string
  default = "arn:aws:acm:eu-west-1:975050270418:certificate/7de29d6d-24e7-4eaa-8a70-97984a30e238"
  
}

variable "hosted_zone_name" {
  description = "The ID of the Route 53 Hosted Zone"
  type        = string
  default = "wordpress-for-test.pp.ua"
}
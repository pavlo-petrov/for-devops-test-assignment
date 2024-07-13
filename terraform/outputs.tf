
############## VPC OUTPUTS #############
output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "vpc_id" {
  value = aws_vpc.main.id
}

############## SUBNETS OUTPUTS #############
output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "public_subnet_cidrs" {
  value = aws_subnet.public_subnet[*].cidr_block  
}

output "public_subnet_azs" {
  value = aws_subnet.public_subnet[*].availability_zone
}

output "admin_subnet_ids" {
  value = aws_subnet.admin_subnet[*].id
}

output "admin_subnet_ids_for_packer" {
  value = aws_subnet.admin_subnet[0].id
}

output "admin_subnet_cidrs" {
  value = aws_subnet.admin_subnet[*].cidr_block
}

output "admin_subnet_azs" {
  value = aws_subnet.admin_subnet[*].availability_zone
}

output "database_subnet_ids" {
  value = aws_subnet.database_subnet[*].id
}

output "database_subnet_cidrs" {
  value = aws_subnet.database_subnet[*].cidr_block
}

output "database_subnet_azs" {
  value = aws_subnet.database_subnet[*].availability_zone
}

##############

output "internet_gateway_id" {
  value = aws_internet_gateway.gw.id
}

output "rds_endpoint" {
  value = split(":", aws_db_instance.default.endpoint)[0]
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis_cluster.cache_nodes[0].address
}

output "redis_port" {
  value = aws_elasticache_cluster.redis_cluster.port
}

output "secutity_group_packer_id" {
  value = aws_security_group.packer_security_group.id
}

output "asg_name_admin_id" {
  value = aws_autoscaling_group.asg1.id
}

output "asg_name_public_id" {
  value = aws_autoscaling_group.asg2.id
}

output "listener_admin_arn" {
  value = aws_lb_listener_rule.wpadmin_rule.arn
}

output "listener_public_arn" {
  value = aws_lb_listener_rule.default_rule.arn
}

output "launch_template_admin_id" {
  value = aws_launch_template.wordpress_public.id
}

output "launch_template_public_id" {
  value = aws_launch_template.wordpress_admin.id
}
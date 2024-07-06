
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
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}

output "load_balancer_arn" {
  value = aws_lb.ecs_alb.arn
}

# output "iam_instance_profile_name" {
#   value = aws_iam_instance_profile.ecs_agent.name
# }

# output "key_name" {
#   value = aws_key_pair.deployer.key_name
# }
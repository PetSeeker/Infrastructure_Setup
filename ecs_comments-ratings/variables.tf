variable "vpc_id" {
  description = "The ID of the VPC."
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs."
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs."
}

variable "security_group_id" {
  description = "The ID of the security group."
}

variable "load_balancer_arn" {
  description = "The ARN of the load balancer."
}

variable "db_name" {
  description = "The name of the database."
}

variable "db_username" {
  description = "The username of the database."
}

variable "db_password" {
  description = "The password of the database."
}

variable "db_host" {
  description = "The host of the database."
}

variable "db_port" {
  description = "The port of the database."
}
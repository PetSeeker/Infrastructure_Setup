output "db_host" {
  value = aws_db_instance.mysql.address
}

output "db_port" {
  value = aws_db_instance.mysql.port
}

output "db_name" {
  value = aws_db_instance.mysql.db_name
}

output "db_username" {
  value = aws_db_instance.mysql.username
}

output "db_password" {
  value = random_string.db-password.result
}

output "db_host" {
    value = aws_db_instance.postgreSQL.address
}

output "db_port" {
    value = aws_db_instance.postgreSQL.port
}

output "db_name" {
    value = aws_db_instance.postgreSQL.db_name
}

output "db_username" {
    value = aws_db_instance.postgreSQL.username
}

output "db_password" {
    value = aws_db_instance.postgreSQL.password
}
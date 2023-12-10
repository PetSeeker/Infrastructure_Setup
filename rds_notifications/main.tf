resource "random_string" "db-password" {
  length  = 32
  upper   = true
  numeric  = true
  special = false
}

resource "aws_security_group" "rds_sg" {
  vpc_id      = var.vpc_id
  name        = "noti-db"
  description = "Allow all inbound for MySQL"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  db_name                = "noti_db"
  engine_version         = "8.0.33" 
  instance_class         = "db.t3.micro"
  username               = "master" 
  password               = random_string.db-password.result
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible   = false
  storage_type           = "gp2"
  storage_encrypted      = true
  multi_az               = false
  identifier             = "noti-db"

  db_subnet_group_name = "mydb-subnet-group"
}

resource "random_string" "db-password" {
  length  = 32
  upper   = true
  numeric  = true
  special = false
}

resource "aws_security_group" "rds_sg" {
    vpc_id      = var.vpc_id
    name        = "profile-man-db"
    description = "Allow all inbound for Postgres"
    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_db_instance" "postgreSQL" {
    allocated_storage    = 20
    engine               = "postgres"
    db_name              = "profile_man_db"
    engine_version       = "15.4"
    instance_class       = "db.t3.micro"
    username             = "postgres"
    password             = random_string.db-password.result
    skip_final_snapshot  = true
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
    publicly_accessible = false
    storage_type = "gp2"
    storage_encrypted = true
    multi_az = false
    identifier           = "profile-man-db"

    db_subnet_group_name = "mydb-subnet-group"
}


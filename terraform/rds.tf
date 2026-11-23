# RDS DB Subnet Group
resource "aws_db_subnet_group" "taskforge" {
  name        = "taskforge-db-subnet-group"
  description = "Private subnets for TaskForge RDS"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "taskforge-db-subnet-group"
    App  = "TaskForge"
  }
}

# TaskForge PostgreSQL Database
resource "aws_db_instance" "taskforge" {
  identifier        = "taskforge-postgres"
  engine            = "postgres"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "taskforge"
  username = "taskforge_admin"
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.taskforge.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "taskforge-postgres"
    App  = "TaskForge"
  }
}

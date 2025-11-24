resource "aws_db_instance" "postgres" {
  identifier     = "${terraform.workspace}-gaia-db"
  engine         = "postgres"
  engine_version = "17.6"
  instance_class = var.rds_instance_class

  allocated_storage = 20

  db_name  = "${terraform.workspace}_gaia_postgres"
  username = "gaia_user"
  password = random_password.postgres_master_password.result

  db_subnet_group_name   = aws_db_subnet_group.rds_sng.name
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]

  publicly_accessible = false
  multi_az            = var.rds_multi_az
  skip_final_snapshot = true

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

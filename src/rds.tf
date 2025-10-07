resource "aws_db_instance" "postgres_db" {
  identifier     = "${terraform.workspace}-gaia-postgres-db"
  engine         = "postgres"
  engine_version = "17.6"
  instance_class = "db.t4g.micro"

  allocated_storage = 20

  db_name  = "${terraform.workspace}_gaia_postgres_db"
  username = "gaia_postgres_user"
  password = random_password.postgres_db_master_password.result

  db_subnet_group_name   = aws_db_subnet_group.rds_sng.name
  vpc_security_group_ids = [aws_security_group.postgres_db_sg.id]

  publicly_accessible = false
  multi_az            = false
  skip_final_snapshot = true

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

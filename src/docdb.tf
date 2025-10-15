resource "aws_docdb_cluster" "main" {
  cluster_identifier     = "${terraform.workspace}-gaia-docdb-cluster"
  engine                 = "docdb"
  master_username        = "gaiadocadmin"
  master_password        = random_password.docdb_master_password.result
  db_subnet_group_name   = aws_docdb_subnet_group.docdb_sng.name
  vpc_security_group_ids = [aws_security_group.gaia_docdb_sg.id]
  skip_final_snapshot    = true

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_docdb_cluster_instance" "main" {
  count              = 1
  identifier         = "${terraform.workspace}-gaia-docdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id

  instance_class = "db.t3.medium"

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

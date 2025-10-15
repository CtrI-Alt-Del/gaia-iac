resource "random_password" "postgres_db_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^{|}~"
}

resource "aws_secretsmanager_secret" "postgres_db_credentials" {
  name = "${terraform.workspace}/postgres_db/credentials"

  tags = {
    IAC = true
  }
}

data "aws_secretsmanager_secret" "clerk_credentials" {
  name = "${terraform.workspace}/clerk/credentials"
}

resource "aws_secretsmanager_secret_version" "postgres_db_password_version" {
  secret_id     = aws_secretsmanager_secret.postgres_db_credentials.id
  secret_string = random_password.postgres_db_master_password.result
}

resource "random_password" "docdb_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&()*+,-./:;<=>?@[]^_`{|}~"
}

resource "aws_secretsmanager_secret" "docdb_credentials" {
  name = "${terraform.workspace}/docdb/credentials"
}

resource "aws_secretsmanager_secret_version" "docdb_credentials_version" {
  secret_id     = aws_secretsmanager_secret.docdb_credentials.id
  secret_string = random_password.docdb_master_password.result
}

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

resource "aws_secretsmanager_secret_version" "postgres_db_password_version" {
  secret_id     = aws_secretsmanager_secret.postgres_db_credentials.id
  secret_string = random_password.postgres_db_master_password.result
}

data "aws_secretsmanager_secret" "clerk_credentials" {
  name = "${terraform.workspace}/clerk/credentials"
}

data "aws_secretsmanager_secret" "mongo_credentials" {
  name = "${terraform.workspace}/mongo/credentials"
}

data "aws_secretsmanager_secret" "mqtt_broker_credentials" {
  name = "${terraform.workspace}/mqtt_broker/credentials"
}

resource "random_password" "postgres_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^{|}~"
}

resource "aws_secretsmanager_secret" "postgres_credentials" {
  name = "${terraform.workspace}/postgres/credentials"

  tags = {
    IAC = true
  }
}

resource "aws_secretsmanager_secret_version" "postgres_password_version" {
  secret_id     = aws_secretsmanager_secret.postgres_credentials.id
  secret_string = random_password.postgres_master_password.result
}

data "aws_secretsmanager_secret" "clerk_secrets" {
  name = "${terraform.workspace}/clerk"
}

data "aws_secretsmanager_secret" "redis_secrets" {
  name = "${terraform.workspace}/redis"
}

data "aws_secretsmanager_secret" "mongo_secrets" {
  name = "${terraform.workspace}/mongo"
}

data "aws_secretsmanager_secret" "mqtt_broker_secrets" {
  name = "${terraform.workspace}/mqtt_broker"
}

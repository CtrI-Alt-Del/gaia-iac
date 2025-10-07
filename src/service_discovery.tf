resource "aws_service_discovery_private_dns_namespace" "gaia_ns" {
  name        = "${terraform.workspace}.gaia.local"
  description = "Namespace de DNS privado para o projeto Gaia"
  vpc         = aws_vpc.main.id

  tags = {
    IAC = true
  }
}

resource "aws_service_discovery_service" "gaia_server_sd" {
  name = "${terraform.workspace}-gaia-server-sd"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.gaia_ns.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  tags = {
    IAC = true
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${terraform.workspace}-vpc"
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${terraform.workspace}-igw"
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${terraform.workspace}-public-a"
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${terraform.workspace}-public-b"
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name        = "${terraform.workspace}-private-a"
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${terraform.workspace}-private-b"
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}


data "aws_availability_zones" "available" {}

resource "aws_security_group" "alb_sg" {
  name        = "${terraform.workspace}-alb-sg"
  description = "Permite trafego HTTP da internet para o ALB"
  vpc_id      = aws_vpc.main.id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "gaia_panel_sg" {
  name        = "${terraform.workspace}-${var.gaia_panel_container_name}-sg"
  description = "Security group para o servico do Gaia Panel"
  vpc_id      = aws_vpc.main.id
  ingress {
    protocol        = "tcp"
    from_port       = var.gaia_panel_container_port
    to_port         = var.gaia_panel_container_port
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "gaia_server_sg" {
  name        = "${terraform.workspace}-${var.gaia_server_container_name}-sg"
  description = "Security group para o servico do Gaia Server"
  vpc_id      = aws_vpc.main.id
  ingress {
    protocol        = "tcp"
    from_port       = var.gaia_server_container_port
    to_port         = var.gaia_server_container_port
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    IAC = true
  }
}

resource "aws_security_group" "gaia_collector_sg" {
  name        = "${terraform.workspace}-${var.gaia_collector_container_name}-sg"
  description = "Security group para o servico do Gaia Collector"
  vpc_id      = aws_vpc.main.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    IAC = true
  }
}

resource "aws_security_group" "postgres_sg" {
  name   = "${terraform.workspace}--db-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.gaia_server_sg.id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    IAC = true
  }
}

resource "aws_db_subnet_group" "rds_sng" {
  name       = "${terraform.workspace}-db-sng"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_security_group" "elasticache_sg" {
  name        = "${terraform.workspace}-elasticache-sg"
  description = "Permite trafego Elasticache de entrada vindo do Gaia Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Acesso Elasticache a partir do Gaia Server"
    protocol        = "tcp"
    from_port       = 6379
    to_port         = 6379
    security_groups = [aws_security_group.gaia_server_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    IAC = true
  }
}

resource "aws_elasticache_subnet_group" "elasticache_sng" {
  name       = "${terraform.workspace}-elasticache-sng"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    IAC = true
  }
}

resource "aws_security_group" "ecs_host_sg" {
  name        = "${terraform.workspace}-ecs-host-sg"
  description = "Security Group para as instancias EC2 do cluster ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    IAC = true
  }
}

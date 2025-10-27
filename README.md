<h1 align="center">Gaia IAC</h1>

<p align="center">
  <strong>Infraestrutura como Código para o Ecossistema Gaia</strong><br>
  Automatização completa da infraestrutura AWS usando Terraform
</p>

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Diagrama da Arquitetura](#diagrama-da-arquitetura)
- [Arquitetura da Infraestrutura](#arquitetura-da-infraestrutura)
  - [1. Rede e VPC](#1-rede-e-vpc)
  - [2. Camada Pública](#2-camada-pública)
  - [3. Camada Privada](#3-camada-privada)
  - [4. Observabilidade e Custos](#4-observabilidade-e-custos)
  - [5. Segurança e Segredos](#5-segurança-e-segredos)
- [Componentes Implementados](#componentes-implementados)
  - [Provisionados](#provisionados)
  - [Planejados](#planejados)
- [Como Usar](#como-usar)
  - [Pré-requisitos](#pré-requisitos)
  - [Preparar o Backend Remoto do Terraform](#preparar-o-backend-remoto-do-terraform)
  - [Configurar Segredos no AWS Secrets Manager](#configurar-segredos-no-aws-secrets-manager)
  - [Execução Manual](#execução-manual)
- [Pipelines CI/CD](#pipelines-cicd)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Principais Saídas](#principais-saídas)

---

## 🎯 Visão Geral

A infraestrutura da plataforma Gaia é descrita integralmente em Terraform e provisionada na AWS com foco em segurança, escalabilidade e automação. O desenho separa cargas públicas e privadas em sub-redes distintas, aproveitando Fargate para execução dos contêineres e serviços gerenciados para banco de dados, cache e observabilidade. Os pipelines em GitHub Actions garantem que qualquer alteração passe por validação e deployments consistentes entre ambientes `dev` (staging) e `prod`.

---

## 📊 Diagrama da Arquitetura

![alt text](./documentation/media/infra-diagram.png)

---

## 🏗️ Arquitetura da Infraestrutura

### 1. Rede e VPC

- VPC dedicada (`10.0.0.0/16`) com DNS habilitado e quatro sub-redes (duas públicas, duas privadas) distribuídas entre Zonas de Disponibilidade.
- Internet Gateway expõe apenas a camada necessária, enquanto um NAT Gateway nas sub-redes públicas permite saída controlada a workloads privados.
- Tabelas de rota isolam tráfego entre camadas, mantendo fluxos explícitos para internet e comunicação leste-oeste.

### 2. Camada Pública

- **Application Load Balancer (ALB)** recebe o tráfego HTTP, aplica regras de host/path e encaminha requisições para os serviços internos.
- **Gaia Panel (frontend)** roda em tarefas Fargate nas sub-redes públicas com IPs públicos e se comunica com a camada privada por meio do ALB e do Cloud Map.

### 3. Camada Privada

- **Gaia Server (backend)** executa em Fargate nas sub-redes privadas, exposto via Service Discovery. Consome PostgreSQL, Redis e segredos do Secrets Manager.
- **Gaia Collector** permanece privado, conectando-se ao broker MQTT (fora do escopo deste módulo) e persistindo dados via `MONGO_URI`.
- **RDS PostgreSQL** provê armazenamento relacional com subnets privadas e acesso restrito ao servidor de aplicação.
- **ElastiCache Redis** entrega cache compartilhado ao Gaia Server, com regras de segurança que aceitam tráfego apenas da aplicação.
- **DocumentDB** permanece planejado; por enquanto, sua conexão é injetada via segredo (`MONGO_URI`) e deve apontar para uma instância existente.

### 4. Observabilidade e Custos

- Grupos de logs no CloudWatch (`/ecs/...`) armazenam métricas e registros das tasks do Panel, Server e Collector.
- Auto Scaling alvo (Application Auto Scaling) ajusta a quantidade de tarefas Fargate conforme o uso de CPU para cada serviço.
- AWS Budgets integrado a um tópico SNS envia alertas por e-mail quando os custos mensais reais ou previstos superam o limite configurado.

### 5. Segurança e Segredos

- Security Groups encadeados controlam cada fluxo: ALB → Panel → Server → RDS/Redis, evitando exposição indevida.
- IAM com OIDC do GitHub Actions concede permissões mínimas para os repositórios `gaia-iac`, `gaia-server`, `gaia-panel` e `gaia-collector` realizarem deploys e interagirem com a AWS.
- Secrets Manager guarda credenciais sensíveis e é consumido pelas tasks ECS através das roles configuradas, garantindo rotação e isolamento por ambiente.
- A política de ECS Exec libera acesso seguro ao console das tasks via Session Manager.

---

## 🧩 Componentes Implementados

### ✅ Provisionados

- 🌐 **VPC e Networking** – Sub-redes públicas/privadas, IGW e NAT configurados.
- ⚖️ **Application Load Balancer** – Regras para frontend e backend, health checks dedicados.
- 🐳 **ECS Fargate Cluster** – Serviços para Panel, Server e Collector com execution role dedicada.
- 🗄️ **RDS PostgreSQL** – Banco relacional privado com senha gerada dinamicamente.
- 🔁 **Service Discovery (Cloud Map)** – DNS interno para o Gaia Server.
- 🔐 **Secrets Manager** – Segredos para banco, Clerk, Mongo e broker MQTT, com IAM restritivo.
- 📦 **ECR Repositories** – Repositórios para as imagens Panel, Server e Collector.
- 🚀 **Auto Scaling** – Policies de CPU para ajustar `desired_count` das tasks.
- 📉 **CloudWatch Logs** – Grupos de logs específicos por serviço.
- 💸 **Budgets + SNS** – Budget mensal com notificações de custo.
- 🧠 **ElastiCache Redis** – Endpoint privado usado pelo Gaia Server.

---

## 🚀 Como Usar

### Pré-requisitos

- Terraform `>= 1.6`
- AWS CLI configurado com credenciais que possuam privilégios para criar os recursos descritos.
- Bucket S3 e tabela DynamoDB destinados ao backend remoto (veja abaixo).
- Acesso ao AWS Secrets Manager para criar/atualizar os segredos exigidos por ambiente.

### Preparar o Backend Remoto do Terraform

O backend definido em `src/provider.tf` assume:

- Bucket S3 `gaia-terraform-state-bucket`
- Tabela DynamoDB `gaia-terraform-state-lock`
- Região `us-east-1`

Crie esses recursos previamente ou ajuste os nomes/atributos no arquivo para refletir a sua conta.

### Configurar Segredos no AWS Secrets Manager

Para cada ambiente (workspace do Terraform), crie os seguintes segredos:

- `<workspace>/clerk/credentials`
  - `CLERK_PUBLISHABLE_KEY`
  - `CLERK_SECRET_KEY`
- `<workspace>/mongo/credentials`
  - `MONGO_URI`
- `<workspace>/mqtt_broker/credentials`
  - `MQTT_BROKER_URL`
  - `MQTT_USERNAME`
  - `MQTT_PASSWORD`
  - `MQTT_PORT`
  - `MQTT_TOPIC`

> O segredo `<workspace>/postgres_db/credentials` é criado automaticamente por este módulo, com senha randômica gerada via Terraform.

### Execução Manual

1. Clone o repositório e acesse a pasta `src`:
   ```bash
   git clone https://github.com/CtrI-Alt-Del/gaia-iac.git
   cd gaia-iac/src
   ```
2. Inicialize o Terraform:
   ```bash
   terraform init
   ```
3. Selecione (ou crie) o workspace desejado:
   ```bash
   terraform workspace select dev || terraform workspace new dev
   ```
4. Ajuste as variáveis conforme necessário em `envs/<workspace>.tfvars`.
5. Planeje e aplique as mudanças:
   ```bash
   terraform plan  -var-file="envs/dev.tfvars"
   terraform apply -var-file="envs/dev.tfvars"
   ```

---

## 🤖 Pipelines CI/Deployment

Os workflows do GitHub Actions automatizam validações e deploys:

- **Continuous Integration (`.github/workflows/ci.yaml`)** é um workflow reutilizável que executa `terraform fmt -check`, `terraform validate` e `terraform plan`. Recebe o ambiente como entrada.
- **Staging Deployment** (`staging-deployment.yaml`) roda em cada push na branch `main`, chamando o workflow de deployment com `environment=dev`.
- **Production Deployment** (`production-deployment.yaml`) é disparado em pushes para a branch `production`, aplicando `envs/prod.tfvars`.
- **Production CI** (`production-ci.yaml`) é acionado em pull requests para a branch `production`, garantindo que alterações críticas passem por `plan` antes do merge.

Configure no repositório:

- Secrets `AWS_ROLE_ARN` e `AWS_REGION` com os valores usados para assumir a role IAM.
- Repository variable `TERRAFORM_VERSION` com a versão que deve ser instalada nas ações.

---

## 📁 Estrutura do Projeto

```
documentation/
└── media/
    └── infra-diagram.png     # Diagrama de referência da arquitetura

src/
├── alb.tf                   # Application Load Balancer e listeners
├── autoscalling.tf          # Regras de auto scaling para os serviços ECS
├── budgets.tf               # Budget mensal conectado ao SNS
├── ecr.tf                   # Repositórios ECR das aplicações
├── ecs.tf                   # Cluster e serviços ECS (Panel, Server, Collector)
├── elasticache.tf           # Replication group Redis e subnet/security groups
├── envs/
│   ├── dev.tfvars           # Overrides para o ambiente de desenvolvimento
│   └── prod.tfvars          # Overrides para o ambiente de produção
├── iam.tf                   # Roles, policies e integrações com OIDC
├── outputs.tf               # Saídas importantes da stack
├── provider.tf              # Provider AWS e backend remoto em S3/DynamoDB
├── rds.tf                   # Instância PostgreSQL e subnet group
├── secrets_manager.tf       # Segredos gerenciados e senhas randômicas
├── service_discovery.tf     # Namespace privado e serviço no Cloud Map
├── sns.tf                   # Tópico e assinatura para alertas de budget
├── variables.tf             # Variáveis com defaults e descrições
└── vpc.tf                   # VPC, sub-redes, NAT, IGW e security groups

.github/
└── workflows/
    ├── ci.yaml
    ├── deployment.yaml
    ├── production-ci.yaml
    ├── production-deployment.yaml
    └── staging-deployment.yaml
```

---

## 📤 Principais Saídas

Após aplicar o Terraform, utilize `terraform output` para obter:

- `alb_dns_name` – endpoint público do ALB.
- `ecr_repository_url` – URL do ECR para publicar a imagem do Gaia Server.
- `db_endpoint` – endpoint interno do PostgreSQL.
- `db_credentials_secret_arn` – ARN do segredo com usuário/senha do banco.
- `elasticache_primary_endpoint` – endpoint do cluster Redis para o Gaia Server.

---

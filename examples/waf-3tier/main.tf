module "service" {
  # 모듈 repo 안 예제라 상대경로를 쓴다. 고객사 repo에서는 반드시 태그 고정:
  # source = "git::https://<GITEA_HOST>/infra/terraform-ncp-modules.git//stacks/web-service?ref=v1.0.0"
  source = "../../stacks/web-service"

  name_prefix    = var.name_prefix
  vpc_no         = var.vpc_no
  login_key_name = var.login_key_name

  existing_subnets = var.existing_subnets
  existing_acgs    = var.existing_acgs
  existing_servers = var.existing_servers

  subnets        = var.subnets
  acgs           = var.acgs
  server_groups  = var.server_groups
  load_balancers = var.load_balancers

  database          = var.database
  database_password = var.database_password
}

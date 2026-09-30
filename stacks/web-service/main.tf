locals {
  engine = try(var.database.engine, null)

  # 키 → 번호 통합 맵 (신규 + 기존)
  subnet_nos = merge(var.existing_subnets, { for k, m in module.subnet : k => m.subnet_no })
  acg_nos    = merge(var.existing_acgs, { for k, m in module.acg : k => m.access_control_group_no })

  default_outbound = tolist([
    { protocol = "TCP", port_range = "1-65535", ip_block = "0.0.0.0/0", source_acg = null, description = "default outbound TCP" },
    { protocol = "UDP", port_range = "1-65535", ip_block = "0.0.0.0/0", source_acg = null, description = "default outbound UDP" },
    { protocol = "ICMP", port_range = null, ip_block = "0.0.0.0/0", source_acg = null, description = "default outbound ICMP" },
  ])
}

# ---------------------------------------------------------------- 서브넷
module "subnet" {
  source   = "../../modules/subnet"
  for_each = var.subnets

  name           = coalesce(each.value.name, "${var.name_prefix}-${each.key}-subnet")
  vpc_no         = var.vpc_no
  cidr           = each.value.cidr
  zone           = each.value.zone
  network_acl_no = each.value.network_acl_no
  subnet_type    = each.value.type
  usage_type     = each.value.usage_type
}

# ---------------------------------------------------------------- ACG
# 1단계: ACG 껍데기만 생성 (규칙 없음)
module "acg" {
  source   = "../../modules/acg"
  for_each = var.acgs

  vpc_no      = var.vpc_no
  name        = coalesce(each.value.name, "${var.name_prefix}-${each.key}-acg")
  description = each.value.description
}

# 2단계: 규칙 적용. ACG끼리 서로 참조(web → was)해도 순환 참조가 생기지 않도록 분리
module "acg_rules" {
  source   = "../../modules/acg"
  for_each = var.acgs

  create                  = false
  access_control_group_no = module.acg[each.key].access_control_group_no

  inbound_rules = [
    for r in each.value.inbound : {
      protocol                       = r.protocol
      port_range                     = r.port_range
      ip_block                       = r.ip_block
      source_access_control_group_no = r.source_acg == null ? null : local.acg_nos[r.source_acg]
      description                    = r.description
    }
  ]

  outbound_rules = [
    for r in(each.value.outbound != null ? each.value.outbound : local.default_outbound) : {
      protocol                       = r.protocol
      port_range                     = r.port_range
      ip_block                       = r.ip_block
      source_access_control_group_no = r.source_acg == null ? null : local.acg_nos[r.source_acg]
      description                    = r.description
    }
  ]
}

# ---------------------------------------------------------------- 서버
module "server" {
  source   = "../../modules/server"
  for_each = var.server_groups

  name_prefix = coalesce(each.value.name_prefix, "${var.name_prefix}-${each.key}")
  instances   = each.value.instances
  description = each.value.description

  server_spec_code  = each.value.server_spec_code
  server_image_name = each.value.server_image_name
  hypervisor_type   = each.value.hypervisor_type
  init_script_no    = each.value.init_script_no

  subnet_no                    = local.subnet_nos[each.value.subnet]
  access_control_group_no_list = [for a in each.value.acgs : local.acg_nos[a]]
  associate_public_ip          = each.value.associate_public_ip

  login_key_name      = var.login_key_name
  protect_termination = each.value.protect_termination
  additional_disks    = each.value.additional_disks
}

# ---------------------------------------------------------------- 로드밸런서
module "lb" {
  source   = "../../modules/lb"
  for_each = var.load_balancers

  create                    = each.value.create
  existing_load_balancer_no = each.value.existing_load_balancer_no

  name            = each.value.create ? coalesce(each.value.name, "${var.name_prefix}-${each.key}-lb") : null
  description     = each.value.description
  network_type    = each.value.network_type
  type            = each.value.type
  subnet_no_list  = [for s in each.value.subnets : local.subnet_nos[s]]
  throughput_type = each.value.throughput_type
  idle_timeout    = each.value.idle_timeout

  vpc_no = coalesce(each.value.vpc_no, var.vpc_no)

  target_groups = {
    for tk, tg in each.value.target_groups : tk => {
      name               = coalesce(tg.name, "${var.name_prefix}-${each.key}-${tk}-tg")
      description        = tg.description
      protocol           = tg.protocol
      target_type        = tg.target_type
      port               = tg.port
      algorithm_type     = tg.algorithm_type
      use_sticky_session = tg.use_sticky_session
      use_proxy_protocol = tg.use_proxy_protocol
      health_check       = tg.health_check
      target_no_list = concat(
        flatten([for g in tg.target_server_groups : values(module.server[g].instance_nos)]),
        [for s in tg.target_existing_servers : var.existing_servers[s]]
      )
    }
  }

  listeners = each.value.listeners
}

# ---------------------------------------------------------------- DB
module "mysql" {
  source   = "../../modules/mysql"
  for_each = local.engine == "mysql" ? { db = var.database } : {}

  service_name = coalesce(each.value.service_name, "${var.name_prefix}-db")
  subnet_no    = local.subnet_nos[each.value.subnet]
  port         = coalesce(each.value.port, 3306)

  user_name     = each.value.user_name
  user_password = var.database_password
  host_ip       = each.value.host_ip
  database_name = each.value.database_name

  engine_version_code = coalesce(each.value.engine_version_code, "8.0.42")
  image_product_code  = each.value.image_product_code
  product_code        = each.value.product_code
  product_name        = each.value.product_name

  ha                  = each.value.ha
  multi_zone          = each.value.multi_zone
  secondary_subnet_no = each.value.secondary_subnet == null ? null : local.subnet_nos[each.value.secondary_subnet]

  backup                = each.value.backup
  backup_time           = coalesce(each.value.backup_time, "02:00")
  backup_retention_days = each.value.backup_retention_days
  storage_encryption    = each.value.storage_encryption
}

module "postgresql" {
  source   = "../../modules/postgresql"
  for_each = local.engine == "postgresql" ? { db = var.database } : {}

  service_name = coalesce(each.value.service_name, "${var.name_prefix}-db")
  vpc_no       = var.vpc_no
  subnet_no    = local.subnet_nos[each.value.subnet]
  client_cidr  = each.value.client_cidr
  port         = coalesce(each.value.port, 5432)

  user_name     = each.value.user_name
  user_password = var.database_password
  database_name = each.value.database_name

  engine_version_code = each.value.engine_version_code
  image_product_code  = each.value.image_product_code
  product_code        = each.value.product_code

  ha                  = each.value.ha
  multi_zone          = each.value.multi_zone
  secondary_subnet_no = each.value.secondary_subnet == null ? null : local.subnet_nos[each.value.secondary_subnet]

  backup                = each.value.backup
  automatic_backup      = each.value.backup_time == null
  backup_time           = each.value.backup_time
  backup_retention_days = each.value.backup_retention_days
  storage_encryption    = each.value.storage_encryption
}

# 이미지 코드 미지정 시 engine_version_code로 조회
data "ncloud_mysql_image_products" "this" {
  count = var.image_product_code == null ? 1 : 0

  filter {
    name   = "engine_version_code"
    values = [var.engine_version_code]
  }
}

# 스펙 코드 미지정 시 product_name(예: "vCPU 2EA, Memory 4GB")으로 조회
data "ncloud_mysql_products" "this" {
  count = var.product_code == null ? 1 : 0

  image_product_code = local.image_product_code

  filter {
    name   = "product_name"
    values = [var.product_name]
  }
}

locals {
  image_product_code = (
    var.image_product_code != null
    ? var.image_product_code
    : data.ncloud_mysql_image_products.this[0].image_product_list[0].image_product_code
  )

  # v0.x 버그 수정: 이전에는 product_name 문자열을 product_code 자리에 그대로 넣고 있었음
  product_code = (
    var.product_code != null
    ? var.product_code
    : data.ncloud_mysql_products.this[0].product_list[0].product_code
  )
}

resource "ncloud_mysql" "this" {
  service_name       = var.service_name
  server_name_prefix = coalesce(var.server_name_prefix, var.service_name)
  subnet_no          = var.subnet_no
  port               = var.port

  user_name     = var.user_name
  user_password = var.user_password
  host_ip       = var.host_ip
  database_name = var.database_name

  image_product_code = local.image_product_code
  product_code       = local.product_code

  is_ha                    = var.ha
  is_multi_zone            = var.ha ? var.multi_zone : false
  standby_master_subnet_no = var.ha && var.multi_zone ? var.secondary_subnet_no : null

  is_backup                    = var.backup
  backup_time                  = var.backup ? var.backup_time : null
  backup_file_retention_period = var.backup ? var.backup_retention_days : null

  is_storage_encryption = var.storage_encryption

  lifecycle {
    precondition {
      condition     = var.product_code != null || var.product_name != null
      error_message = "product_code 또는 product_name 중 하나는 지정해야 합니다."
    }
    precondition {
      condition     = !(var.ha && var.multi_zone) || var.secondary_subnet_no != null
      error_message = "multi_zone = true 이면 secondary_subnet_no(다른 존의 서브넷)가 필요합니다."
    }
  }
}

# v0.x 주소 → v1 주소
moved {
  from = ncloud_mysql.mysql
  to   = ncloud_mysql.this
}

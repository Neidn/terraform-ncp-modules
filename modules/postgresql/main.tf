# 이미지 코드 미지정 시 engine_version_code로 조회
data "ncloud_postgresql_image_products" "this" {
  count = var.image_product_code == null ? 1 : 0

  filter {
    name   = "product_type"
    values = ["LINUX"]
  }

  dynamic "filter" {
    for_each = var.engine_version_code != null ? [1] : []
    content {
      name   = "engine_version_code"
      values = [var.engine_version_code]
    }
  }
}

locals {
  image_product_code = (
    var.image_product_code != null
    ? var.image_product_code
    : data.ncloud_postgresql_image_products.this[0].image_product_list[0].product_code
  )
}

resource "ncloud_postgresql" "this" {
  service_name       = var.service_name
  server_name_prefix = coalesce(var.server_name_prefix, var.service_name)

  user_name     = var.user_name
  user_password = var.user_password

  vpc_no      = var.vpc_no
  subnet_no   = var.subnet_no
  client_cidr = var.client_cidr
  port        = var.port

  database_name = var.database_name

  image_product_code  = local.image_product_code
  product_code        = var.product_code
  engine_version_code = var.engine_version_code

  data_storage_type_code = var.data_storage_type_code
  storage_encryption     = var.storage_encryption

  ha                  = var.ha
  multi_zone          = var.ha ? var.multi_zone : false
  secondary_subnet_no = var.ha && var.multi_zone ? var.secondary_subnet_no : null

  backup                       = var.backup
  automatic_backup             = var.backup ? var.automatic_backup : null
  backup_time                  = var.backup && !var.automatic_backup ? var.backup_time : null
  backup_file_retention_period = var.backup ? var.backup_retention_days : null
  backup_file_storage_count    = var.backup ? var.backup_file_storage_count : null
  backup_file_compression      = var.backup ? var.backup_file_compression : null

  lifecycle {
    precondition {
      condition     = !(var.ha && var.multi_zone) || var.secondary_subnet_no != null
      error_message = "multi_zone = true 이면 secondary_subnet_no(다른 존의 서브넷)가 필요합니다."
    }
    precondition {
      condition     = !var.backup || var.automatic_backup || var.backup_time != null
      error_message = "automatic_backup = false 이면 backup_time이 필요합니다."
    }
  }
}

# v0.x 주소 → v1 주소
moved {
  from = ncloud_postgresql.postgresql
  to   = ncloud_postgresql.this
}

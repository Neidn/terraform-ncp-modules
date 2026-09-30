# acg + acg_rules 통합 모듈
#   create = true  : ACG 생성 (+ 규칙이 있으면 규칙까지)
#   create = false : 기존 ACG(access_control_group_no)에 규칙만 적용
#
# 주의: ACG 하나당 ncloud_access_control_group_rule 리소스는 하나만 둔다.
# 이 리소스가 ACG 규칙 "전체"를 관리하므로, 기존 ACG에 적용하면
# 여기 정의되지 않은 기존 규칙은 apply 시 삭제된다.

resource "ncloud_access_control_group" "this" {
  count = var.create ? 1 : 0

  vpc_no      = var.vpc_no
  name        = var.name
  description = var.description

  lifecycle {
    precondition {
      condition     = var.vpc_no != null
      error_message = "create = true 이면 vpc_no가 필요합니다."
    }
  }
}

locals {
  access_control_group_no = var.create ? ncloud_access_control_group.this[0].id : var.access_control_group_no
  manage_rules            = length(var.inbound_rules) + length(var.outbound_rules) > 0
}

resource "ncloud_access_control_group_rule" "this" {
  count = local.manage_rules ? 1 : 0

  access_control_group_no = local.access_control_group_no

  dynamic "inbound" {
    for_each = var.inbound_rules
    content {
      protocol                       = inbound.value.protocol
      ip_block                       = inbound.value.ip_block
      source_access_control_group_no = inbound.value.source_access_control_group_no
      port_range                     = inbound.value.port_range
      description                    = inbound.value.description
    }
  }

  dynamic "outbound" {
    for_each = var.outbound_rules
    content {
      protocol                       = outbound.value.protocol
      ip_block                       = outbound.value.ip_block
      source_access_control_group_no = outbound.value.source_access_control_group_no
      port_range                     = outbound.value.port_range
      description                    = outbound.value.description
    }
  }

  lifecycle {
    precondition {
      condition     = local.access_control_group_no != null
      error_message = "create = false 이면 access_control_group_no가 필요합니다."
    }
  }
}

# v0.x acg 모듈(단일 ACG) 주소 → v1 주소
moved {
  from = ncloud_access_control_group.this
  to   = ncloud_access_control_group.this[0]
}

# create = true  : LB 생성 + 대상 그룹 + 리스너
# create = false : 기존 LB(existing_load_balancer_no)에 대상 그룹/리스너만 추가
#
# 기존 LB의 "이미 있는 리스너"를 수정하려면, 먼저 루트 모듈에서 import 블록으로
# 해당 리스너를 이 모듈의 ncloud_lb_listener.this["<키>"] 주소로 가져온 뒤 수정한다.
# (import 없이 같은 포트로 리스너를 정의하면 생성 단계에서 포트 중복 오류가 난다)

locals {
  load_balancer_no = var.create ? ncloud_lb.this[0].load_balancer_no : var.existing_load_balancer_no
}

resource "ncloud_lb" "this" {
  count = var.create ? 1 : 0

  name            = var.name
  description     = var.description
  network_type    = var.network_type
  type            = var.type
  subnet_no_list  = var.subnet_no_list
  idle_timeout    = var.type == "NETWORK" ? null : var.idle_timeout
  throughput_type = var.throughput_type

  lifecycle {
    precondition {
      condition     = var.name != null && length(var.subnet_no_list) > 0
      error_message = "create = true 이면 name과 subnet_no_list가 필요합니다."
    }
  }
}

resource "ncloud_lb_target_group" "this" {
  for_each = var.target_groups

  name        = each.value.name
  description = each.value.description
  vpc_no      = var.vpc_no
  protocol    = each.value.protocol
  target_type = each.value.target_type
  port        = each.value.port

  algorithm_type     = each.value.algorithm_type
  use_sticky_session = each.value.use_sticky_session
  use_proxy_protocol = each.value.use_proxy_protocol

  health_check {
    protocol       = each.value.health_check.protocol
    http_method    = contains(["HTTP", "HTTPS"], each.value.health_check.protocol) ? each.value.health_check.http_method : null
    url_path       = contains(["HTTP", "HTTPS"], each.value.health_check.protocol) ? each.value.health_check.url_path : null
    port           = coalesce(each.value.health_check.port, each.value.port)
    cycle          = each.value.health_check.cycle
    up_threshold   = each.value.health_check.up_threshold
    down_threshold = each.value.health_check.down_threshold
  }

  lifecycle {
    precondition {
      condition     = var.vpc_no != null
      error_message = "대상 그룹을 만들려면 vpc_no가 필요합니다 (대상 서버가 속한 VPC)."
    }
  }
}

resource "ncloud_lb_target_group_attachment" "this" {
  for_each = { for k, v in var.target_groups : k => v if length(v.target_no_list) > 0 }

  target_group_no = ncloud_lb_target_group.this[each.key].target_group_no
  target_no_list  = each.value.target_no_list
}

resource "ncloud_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_no = local.load_balancer_no
  target_group_no = (
    each.value.target_group_no != null
    ? each.value.target_group_no
    : ncloud_lb_target_group.this[each.value.target_group_key].target_group_no
  )
  protocol = each.value.protocol
  port     = each.value.port

  tls_min_version_type = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.tls_min_version_type : null
  ssl_certificate_no   = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.ssl_certificate_no : null
  use_http2            = each.value.protocol == "HTTPS" ? each.value.use_http2 : null

  lifecycle {
    precondition {
      condition     = local.load_balancer_no != null
      error_message = "create = false 이면 existing_load_balancer_no가 필요합니다."
    }
  }
}

# v0.x lb 모듈 주소 → v1 주소
moved {
  from = ncloud_lb.this
  to   = ncloud_lb.this[0]
}

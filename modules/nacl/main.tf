resource "ncloud_network_acl" "this" {
  vpc_no      = var.vpc_no
  name        = var.name
  description = var.description
}

# 주의: NACL 하나당 ncloud_network_acl_rule 리소스는 하나만 둔다.
# 이 리소스가 NACL의 규칙 전체를 관리하므로, 여기 없는 규칙은 apply 시 삭제된다.
resource "ncloud_network_acl_rule" "this" {
  count = length(var.inbound_rules) + length(var.outbound_rules) > 0 ? 1 : 0

  network_acl_no = ncloud_network_acl.this.id

  dynamic "inbound" {
    for_each = var.inbound_rules
    content {
      priority            = inbound.value.priority
      protocol            = inbound.value.protocol
      rule_action         = inbound.value.rule_action
      ip_block            = inbound.value.ip_block
      deny_allow_group_no = inbound.value.deny_allow_group_no
      port_range          = inbound.value.port_range
      description         = inbound.value.description
    }
  }

  dynamic "outbound" {
    for_each = var.outbound_rules
    content {
      priority            = outbound.value.priority
      protocol            = outbound.value.protocol
      rule_action         = outbound.value.rule_action
      ip_block            = outbound.value.ip_block
      deny_allow_group_no = outbound.value.deny_allow_group_no
      port_range          = outbound.value.port_range
      description         = outbound.value.description
    }
  }
}

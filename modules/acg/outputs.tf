output "access_control_group_no" {
  description = "ACG 번호 (생성한 ACG 또는 입력받은 기존 ACG)"
  value       = local.access_control_group_no
}

output "name" {
  description = "ACG 이름 (create = false 이면 null)"
  value       = try(ncloud_access_control_group.this[0].name, null)
}

output "rules_managed" {
  description = "이 모듈이 ACG 규칙 전체를 관리하고 있는지 여부"
  value       = local.manage_rules
}

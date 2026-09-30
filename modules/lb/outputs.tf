output "load_balancer_no" {
  description = "LB 번호 (생성한 LB 또는 재사용한 기존 LB)"
  value       = local.load_balancer_no
}

output "load_balancer_domain" {
  description = "LB 도메인 (create = true 일 때만). WAF의 백엔드 대상으로 등록할 때 사용"
  value       = try(ncloud_lb.this[0].domain, null)
}

output "load_balancer_ip_list" {
  description = "LB IP 목록 (create = true 일 때만)"
  value       = try(ncloud_lb.this[0].ip_list, null)
}

output "target_group_nos" {
  description = "대상 그룹 키 → 번호"
  value       = { for k, tg in ncloud_lb_target_group.this : k => tg.target_group_no }
}

output "listener_nos" {
  description = "리스너 키 → 번호"
  value       = { for k, l in ncloud_lb_listener.this : k => l.listener_no }
}

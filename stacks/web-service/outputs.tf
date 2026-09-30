output "subnet_nos" {
  description = "서브넷 키 → 번호 (신규 + 기존)"
  value       = local.subnet_nos
}

output "acg_nos" {
  description = "ACG 키 → 번호 (신규 + 기존)"
  value       = local.acg_nos
}

output "servers" {
  description = "서버 그룹 → 서버 키 → {name, instance_no, zone, private_ip, public_ip}"
  value       = { for k, m in module.server : k => m.servers }
}

output "ansible_inventory" {
  description = "Ansible 인벤토리용: 서버 그룹 → {서버 이름 → 사설 IP}"
  value = {
    for g, m in module.server : g => { for k, s in m.servers : s.name => s.private_ip }
  }
}

output "load_balancers" {
  description = "LB 키 → {load_balancer_no, domain, target_group_nos, listener_nos}. internal LB의 domain을 WAF 백엔드로 등록"
  value = {
    for k, m in module.lb : k => {
      load_balancer_no = m.load_balancer_no
      domain           = m.load_balancer_domain
      target_group_nos = m.target_group_nos
      listener_nos     = m.listener_nos
    }
  }
}

output "database" {
  description = "DB 접속 정보 (없으면 null)"
  value = one(concat(
    [for m in values(module.mysql) : { engine = "mysql", endpoint = m.private_domain, port = m.port, database = m.database_name }],
    [for m in values(module.postgresql) : { engine = "postgresql", endpoint = m.private_domain, port = m.port, database = m.database_name }],
  ))
}

output "servers" {
  description = "서버 키별 상세 정보"
  value = {
    for k, s in ncloud_server.this : k => {
      name        = s.name
      instance_no = s.instance_no
      zone        = s.zone
      private_ip  = ncloud_network_interface.this["${k}-0"].private_ip
      public_ip   = try(ncloud_public_ip.this[k].public_ip, null)
    }
  }
}

output "instance_nos" {
  description = "서버 키 → 인스턴스 번호 (LB 대상 그룹 등록용)"
  value       = { for k, s in ncloud_server.this : k => s.instance_no }
}

output "private_ips" {
  description = "서버 키 → NIC 0번 사설 IP (Ansible 인벤토리용)"
  value       = { for k, s in ncloud_server.this : k => ncloud_network_interface.this["${k}-0"].private_ip }
}

output "network_interface_nos" {
  description = "'{서버키}-{NIC순번}' → NIC 번호"
  value       = { for k, n in ncloud_network_interface.this : k => n.id }
}

output "block_storage_nos" {
  description = "'{서버키}-{디스크키}' → 블록 스토리지 번호"
  value       = { for k, b in ncloud_block_storage.this : k => b.id }
}

output "login_key_private_key" {
  description = "create_login_key = true 일 때 생성된 private key"
  value       = try(ncloud_login_key.this[0].private_key, null)
  sensitive   = true
}

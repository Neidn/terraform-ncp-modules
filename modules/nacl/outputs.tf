output "network_acl_no" {
  description = "NACL 번호"
  value       = ncloud_network_acl.this.id
}

output "name" {
  description = "NACL 이름"
  value       = ncloud_network_acl.this.name
}

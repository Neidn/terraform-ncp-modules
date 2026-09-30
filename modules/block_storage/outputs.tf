output "block_storage_nos" {
  description = "스토리지 이름 → 번호"
  value       = { for k, b in ncloud_block_storage.this : k => b.id }
}

output "device_names" {
  description = "스토리지 이름 → OS 디바이스 경로 (Ansible 마운트용)"
  value       = { for k, b in ncloud_block_storage.this : k => b.device_name }
}

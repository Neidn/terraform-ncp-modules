output "subnet_no" {
  description = "서브넷 번호"
  value       = ncloud_subnet.this.id
}

output "name" {
  description = "서브넷 이름"
  value       = ncloud_subnet.this.name
}

output "cidr" {
  description = "서브넷 CIDR"
  value       = ncloud_subnet.this.subnet
}

output "zone" {
  description = "존 코드"
  value       = ncloud_subnet.this.zone
}

output "subnet_type" {
  description = "PUBLIC / PRIVATE"
  value       = ncloud_subnet.this.subnet_type
}

output "usage_type" {
  description = "서브넷 용도"
  value       = ncloud_subnet.this.usage_type
}

output "id" {
  description = "Cloud DB for PostgreSQL 인스턴스 ID"
  value       = ncloud_postgresql.this.id
}

output "service_name" {
  description = "서비스 이름"
  value       = ncloud_postgresql.this.service_name
}

output "private_domain" {
  description = "Primary 접속 도메인 (사설)"
  value       = try(ncloud_postgresql.this.postgresql_server_list[0].private_domain, null)
}

output "port" {
  description = "접속 포트"
  value       = ncloud_postgresql.this.port
}

output "database_name" {
  description = "초기 DB 이름"
  value       = var.database_name
}

output "access_control_group_no_list" {
  description = "Cloud DB가 자동 생성한 ACG 번호 목록"
  value       = ncloud_postgresql.this.access_control_group_no_list
}

output "server_list" {
  description = "DB 서버 목록 상세"
  value       = ncloud_postgresql.this.postgresql_server_list
}

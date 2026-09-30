output "id" {
  description = "Cloud DB for MySQL 인스턴스 ID"
  value       = ncloud_mysql.this.id
}

output "service_name" {
  description = "서비스 이름"
  value       = ncloud_mysql.this.service_name
}

output "private_domain" {
  description = "Primary 접속 도메인 (사설)"
  value       = try(ncloud_mysql.this.mysql_server_list[0].private_domain, null)
}

output "port" {
  description = "접속 포트"
  value       = ncloud_mysql.this.port
}

output "database_name" {
  description = "초기 DB 이름"
  value       = var.database_name
}

output "server_list" {
  description = "DB 서버 목록 상세"
  value       = ncloud_mysql.this.mysql_server_list
}

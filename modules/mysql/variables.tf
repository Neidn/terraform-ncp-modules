# ---------------------------------------------------------------- 이름/네트워크
variable "service_name" {
  description = "Cloud DB 서비스 이름. v0.x의 server_name 값을 그대로 넣으면 기존 리소스와 동일"
  type        = string
}

variable "server_name_prefix" {
  description = "DB 서버 이름 prefix. 미지정 시 service_name 사용"
  type        = string
  default     = null
}

variable "subnet_no" {
  description = "DB를 생성할 서브넷 번호 (Private 서브넷 권장)"
  type        = string
}

variable "port" {
  description = "MySQL 포트"
  type        = number
  default     = 3306
  nullable    = false

  validation {
    condition     = var.port == 3306 || (var.port >= 10000 && var.port <= 20000)
    error_message = "port는 3306 또는 10000~20000 사이여야 합니다."
  }
}

# ---------------------------------------------------------------- 계정/DB
variable "user_name" {
  description = "DB 관리자 계정 (4~16자)"
  type        = string

  validation {
    condition     = length(var.user_name) >= 4 && length(var.user_name) <= 16
    error_message = "user_name은 4~16자여야 합니다."
  }
}

variable "user_password" {
  description = "DB 관리자 비밀번호 (8~20자). tfvars에 쓰지 말고 TF_VAR_로 주입"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.user_password) >= 8 && length(var.user_password) <= 20
    error_message = "user_password는 8~20자여야 합니다."
  }
}

variable "host_ip" {
  description = <<-EOT
    관리자 계정 접속 허용 호스트 (MySQL host 형식, 예: "10.10.%" 또는 "10.10.11.%").
    "%"(전체 허용)는 v0.x 기본값이었으나 이제 명시적으로 지정해야 한다.
  EOT
  type        = string
  nullable    = false
}

variable "database_name" {
  description = "초기 생성 DB 이름. v0.x에서는 user_name과 동일하게 강제되었음 (기존 리소스 이관 시 같은 값 지정)"
  type        = string
}

# ---------------------------------------------------------------- 버전/스펙
variable "engine_version_code" {
  description = "MySQL 엔진 버전 (image_product_code 미지정 시 조회 기준)"
  type        = string
  default     = "8.0.42"
  nullable    = false
}

variable "image_product_code" {
  description = "이미지 상품 코드. 지정하면 engine_version_code 조회를 건너뜀"
  type        = string
  default     = null
}

variable "product_code" {
  description = "스펙 상품 코드 (예: SVR.VDBAS.STAND.C002.M008...). product_name보다 우선"
  type        = string
  default     = null
}

variable "product_name" {
  description = "스펙 이름 (예: \"vCPU 2EA, Memory 4GB\"). product_code 미지정 시 조회에 사용"
  type        = string
  default     = null
}

# ---------------------------------------------------------------- HA/백업/보안
variable "ha" {
  description = "HA(Standby Master) 구성 여부. 운영/개발 구분이 중요하므로 기본값 없이 명시"
  type        = bool
}

variable "multi_zone" {
  description = "HA를 멀티 존으로 구성할지 여부 (ha = true 일 때만 유효)"
  type        = bool
  default     = false
  nullable    = false
}

variable "secondary_subnet_no" {
  description = "Standby Master용 다른 존 서브넷 번호 (multi_zone = true 일 때 필수)"
  type        = string
  default     = null
}

variable "backup" {
  description = "자동 백업 사용 여부"
  type        = bool
  default     = true
  nullable    = false
}

variable "backup_time" {
  description = "백업 시작 시각 HH:MM (KST)"
  type        = string
  default     = "02:00"
  nullable    = false

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_time))
    error_message = "backup_time은 HH:MM 형식이어야 합니다."
  }
}

variable "backup_retention_days" {
  description = "백업 보관 일수 (1~30)"
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 30
    error_message = "backup_retention_days는 1~30 사이여야 합니다."
  }
}

variable "storage_encryption" {
  description = "스토리지 암호화 여부. 생성 후 변경 불가(변경 시 재생성)이므로 기본값 없이 명시. 공공기관은 true 권장"
  type        = bool
}

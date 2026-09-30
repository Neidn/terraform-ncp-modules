# ---------------------------------------------------------------- 이름/네트워크
variable "service_name" {
  description = "Cloud DB 서비스 이름 (3~30자)"
  type        = string

  validation {
    condition     = length(var.service_name) >= 3 && length(var.service_name) <= 30
    error_message = "service_name은 3~30자여야 합니다."
  }
}

variable "server_name_prefix" {
  description = "DB 서버 이름 prefix (3~20자, 소문자/숫자/하이픈). 미지정 시 service_name 사용"
  type        = string
  default     = null

  validation {
    condition     = var.server_name_prefix == null || can(regex("^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$", var.server_name_prefix))
    error_message = "server_name_prefix는 3~20자, 소문자/숫자/하이픈이며 영숫자로 시작·끝나야 합니다."
  }
}

variable "vpc_no" {
  description = "DB를 생성할 VPC 번호"
  type        = string
}

variable "subnet_no" {
  description = "DB를 생성할 서브넷 번호 (Private 서브넷 권장)"
  type        = string
}

variable "client_cidr" {
  description = "접속 허용 CIDR (예: WAS 서브넷 10.10.12.0/24). 0.0.0.0/0 지양"
  type        = string
  nullable    = false

  validation {
    condition     = can(cidrhost(var.client_cidr, 0))
    error_message = "client_cidr는 올바른 CIDR 표기여야 합니다."
  }
}

variable "port" {
  description = "PostgreSQL 포트"
  type        = number
  default     = 5432
  nullable    = false

  # v0.x 버그 수정: 기본값 5432가 validation(10000~20000)에 걸려 항상 실패하던 문제
  validation {
    condition     = var.port == 5432 || (var.port >= 10000 && var.port <= 20000)
    error_message = "port는 5432 또는 10000~20000 사이여야 합니다."
  }
}

# ---------------------------------------------------------------- 계정/DB
variable "user_name" {
  description = "DB 관리자 계정 (4~16자, 영문 시작)"
  type        = string

  validation {
    condition     = length(var.user_name) >= 4 && length(var.user_name) <= 16 && can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", var.user_name))
    error_message = "user_name은 4~16자, 영문으로 시작하고 영문/숫자/_/-만 가능합니다."
  }
}

variable "user_password" {
  description = "DB 관리자 비밀번호 (8~20자, 문자·숫자·특수문자 포함). tfvars에 쓰지 말고 TF_VAR_로 주입"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.user_password) >= 8 && length(var.user_password) <= 20
    error_message = "user_password는 8~20자여야 합니다."
  }
}

variable "database_name" {
  description = "초기 생성 DB 이름 (1~30자, 영문 시작)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,29}$", var.database_name))
    error_message = "database_name은 1~30자, 영문으로 시작하고 영문/숫자/_/-만 가능합니다."
  }
}

# ---------------------------------------------------------------- 버전/스펙
variable "engine_version_code" {
  description = "엔진 버전 (예: 14.x). image_product_code 미지정 시 조회 기준"
  type        = string
  default     = null
}

variable "image_product_code" {
  description = "이미지 상품 코드. 지정하면 조회를 건너뜀"
  type        = string
  default     = null
}

variable "product_code" {
  description = "스펙 상품 코드. v0.x는 미지정 시 조회 결과 첫 번째 스펙을 자동 선택했으나(예측 불가) 이제 필수"
  type        = string
  nullable    = false
}

variable "data_storage_type_code" {
  description = "스토리지 타입 (G2: SSD, G3: CB2 등). 미지정 시 시스템 기본"
  type        = string
  default     = null
}

variable "storage_encryption" {
  description = "스토리지 암호화 여부. 생성 후 변경 불가(변경 시 재생성)이므로 기본값 없이 명시. 공공기관은 true 권장"
  type        = bool
}

# ---------------------------------------------------------------- HA/백업
variable "ha" {
  description = "HA(Secondary) 구성 여부. 기본값 없이 명시"
  type        = bool
}

variable "multi_zone" {
  description = "HA를 멀티 존으로 구성할지 여부 (ha = true 일 때만 유효)"
  type        = bool
  default     = false
  nullable    = false
}

variable "secondary_subnet_no" {
  description = "Secondary용 다른 존 서브넷 번호 (multi_zone = true 일 때 필수)"
  type        = string
  default     = null
}

variable "backup" {
  description = "백업 사용 여부"
  type        = bool
  default     = true
  nullable    = false
}

variable "automatic_backup" {
  description = "백업 시각 자동 지정 여부. false면 backup_time 필요"
  type        = bool
  default     = true
  nullable    = false
}

variable "backup_time" {
  description = "백업 시작 시각 HH:MM (KST). automatic_backup = false 일 때 사용"
  type        = string
  default     = null

  validation {
    condition     = var.backup_time == null || can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_time))
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

variable "backup_file_storage_count" {
  description = "보관할 백업 파일 개수 (1~30)"
  type        = number
  default     = null

  validation {
    condition     = var.backup_file_storage_count == null || (var.backup_file_storage_count >= 1 && var.backup_file_storage_count <= 30)
    error_message = "backup_file_storage_count는 1~30 사이여야 합니다."
  }
}

variable "backup_file_compression" {
  description = "백업 파일 압축 여부"
  type        = bool
  default     = true
  nullable    = false
}

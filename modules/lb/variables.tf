# ---------------------------------------------------------------- 모드
variable "create" {
  description = "true: LB 신규 생성 / false: 기존 LB(existing_load_balancer_no)에 대상 그룹·리스너만 추가"
  type        = bool
  default     = true
  nullable    = false
}

variable "existing_load_balancer_no" {
  description = "재사용할 기존 LB 번호 (create = false 일 때 필수)"
  type        = string
  default     = null
}

# ---------------------------------------------------------------- LB (create = true 일 때만 사용)
variable "name" {
  description = "LB 이름 (3~30자). 규칙 예: {고객코드}-{환경}-{pub|pri}-{용도}-lb"
  type        = string
  default     = null
}

variable "description" {
  description = "LB 설명 (서비스 도메인 등 기재 권장)"
  type        = string
  default     = "Managed by Terraform"
}

variable "network_type" {
  description = "PUBLIC 또는 PRIVATE"
  type        = string
  default     = "PUBLIC"
  nullable    = false

  validation {
    condition     = contains(["PUBLIC", "PRIVATE"], var.network_type)
    error_message = "network_type은 PUBLIC 또는 PRIVATE이어야 합니다."
  }
}

variable "type" {
  description = "APPLICATION, NETWORK, NETWORK_PROXY"
  type        = string
  default     = "APPLICATION"
  nullable    = false

  validation {
    condition     = contains(["APPLICATION", "NETWORK", "NETWORK_PROXY"], var.type)
    error_message = "type은 APPLICATION, NETWORK, NETWORK_PROXY 중 하나여야 합니다."
  }
}

variable "subnet_no_list" {
  description = "LB를 배치할 서브넷 번호 목록 (LB 전용 서브넷, usage_type = LOADB)"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "idle_timeout" {
  description = "유휴 타임아웃(초). NETWORK 타입에는 적용되지 않음"
  type        = number
  default     = 60
  nullable    = false

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 3600
    error_message = "idle_timeout은 1~3600 사이여야 합니다."
  }
}

variable "throughput_type" {
  description = "SMALL, MEDIUM, LARGE, XLARGE (APPLICATION/NETWORK_PROXY), DYNAMIC (NETWORK)"
  type        = string
  default     = "SMALL"
  nullable    = false

  validation {
    condition     = contains(["SMALL", "MEDIUM", "LARGE", "XLARGE", "DYNAMIC"], var.throughput_type)
    error_message = "throughput_type은 SMALL, MEDIUM, LARGE, XLARGE, DYNAMIC 중 하나여야 합니다."
  }
}

# ---------------------------------------------------------------- 대상 그룹
variable "vpc_no" {
  description = "대상 그룹의 VPC 번호 = 대상 서버가 속한 VPC (WAF 앞단 LB라면 보안 VPC)"
  type        = string
  default     = null
}

variable "target_groups" {
  description = <<-EOT
    생성할 대상 그룹. 키는 리스너의 target_group_key에서 참조한다.
    - protocol: TCP, UDP, PROXY_TCP, HTTP, HTTPS
    - health_check.port 미지정 시 대상 그룹 port 사용
    - target_no_list: 등록할 서버 인스턴스 번호 목록
  EOT
  type = map(object({
    name               = string
    description        = optional(string)
    protocol           = string
    target_type        = optional(string, "VSVR")
    port               = optional(number, 80)
    algorithm_type     = optional(string, "RR")
    use_sticky_session = optional(bool)
    use_proxy_protocol = optional(bool)
    health_check = object({
      protocol       = string
      port           = optional(number)
      http_method    = optional(string, "HEAD")
      url_path       = optional(string, "/")
      cycle          = optional(number, 30)
      up_threshold   = optional(number, 2)
      down_threshold = optional(number, 2)
    })
    target_no_list = optional(list(string), [])
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for tg in values(var.target_groups) : contains(["TCP", "UDP", "PROXY_TCP", "HTTP", "HTTPS"], tg.protocol)])
    error_message = "대상 그룹 protocol은 TCP, UDP, PROXY_TCP, HTTP, HTTPS 중 하나여야 합니다."
  }
  validation {
    condition     = alltrue([for tg in values(var.target_groups) : contains(["RR", "SIPHS", "LC", "MH"], tg.algorithm_type)])
    error_message = "algorithm_type은 RR, SIPHS, LC, MH 중 하나여야 합니다."
  }
  validation {
    condition     = alltrue([for tg in values(var.target_groups) : length(tg.name) >= 3 && length(tg.name) <= 30])
    error_message = "대상 그룹 이름은 3~30자여야 합니다."
  }
}

# ---------------------------------------------------------------- 리스너
variable "listeners" {
  description = <<-EOT
    생성할 리스너. target_group_key(이 모듈의 대상 그룹) 또는 target_group_no(기존 대상 그룹) 중 하나를 지정.
    - protocol: HTTP, HTTPS (APPLICATION) / TCP, UDP (NETWORK) / TCP, TLS (NETWORK_PROXY)
    - HTTPS/TLS는 ssl_certificate_no 필수, tls_min_version_type 기본 TLSV12
  EOT
  type = map(object({
    protocol             = string
    port                 = number
    target_group_key     = optional(string)
    target_group_no      = optional(string)
    ssl_certificate_no   = optional(string)
    tls_min_version_type = optional(string, "TLSV12")
    use_http2            = optional(bool)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for l in values(var.listeners) : contains(["HTTP", "HTTPS", "TCP", "UDP", "TLS"], l.protocol)])
    error_message = "리스너 protocol은 HTTP, HTTPS, TCP, UDP, TLS 중 하나여야 합니다."
  }
  validation {
    condition     = alltrue([for l in values(var.listeners) : l.port >= 1 && l.port <= 65534])
    error_message = "리스너 port는 1~65534 사이여야 합니다."
  }
  validation {
    condition     = alltrue([for l in values(var.listeners) : (l.target_group_key != null) != (l.target_group_no != null)])
    error_message = "각 리스너는 target_group_key 또는 target_group_no 중 정확히 하나만 지정해야 합니다."
  }
  validation {
    condition     = alltrue([for l in values(var.listeners) : !contains(["HTTPS", "TLS"], l.protocol) || l.ssl_certificate_no != null])
    error_message = "HTTPS/TLS 리스너는 ssl_certificate_no가 필요합니다."
  }
  validation {
    condition     = alltrue([for l in values(var.listeners) : contains(["TLSV10", "TLSV11", "TLSV12"], l.tls_min_version_type)])
    error_message = "tls_min_version_type은 TLSV10, TLSV11, TLSV12 중 하나여야 합니다. (공공기관은 TLSV12 권장)"
  }
}

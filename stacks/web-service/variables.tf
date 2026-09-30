# =====================================================================
# 공통
# =====================================================================
variable "name_prefix" {
  description = "리소스 이름 prefix. {고객코드}-{환경} (예: svc-prd). 각 리소스는 {name_prefix}-{키}-... 로 이름이 정해짐"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name_prefix))
    error_message = "name_prefix는 소문자로 시작, 소문자/숫자/하이픈 2~20자여야 합니다."
  }
}

variable "vpc_no" {
  description = "서비스가 배치될 기존 VPC 번호 (스택은 VPC를 만들지 않음)"
  type        = string
}

variable "login_key_name" {
  description = "서버 그룹 공통 로그인 키 이름 (server_groups가 있으면 필수)"
  type        = string
  default     = null
}

# =====================================================================
# 기존 리소스 참조 (키 → 번호)
# 스택 안의 모든 참조는 "키"로 한다. 콘솔에서 만든/다른 state의 리소스는
# 여기에 번호를 등록하고 키로 참조한다. 번호를 다른 곳에 직접 쓰지 않는다.
# =====================================================================
variable "existing_subnets" {
  description = "기존 서브넷 키 → 서브넷 번호 (예: { waf-lb = \"<SUBNET_NO>\" })"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "existing_acgs" {
  description = "기존 ACG 키 → ACG 번호. 스택은 기존 ACG의 규칙을 절대 수정하지 않음 (참조만)"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "existing_servers" {
  description = "기존 서버 키 → 인스턴스 번호 (예: WAF 서버, 이관 전 웹서버). LB 대상 등록용"
  type        = map(string)
  default     = {}
  nullable    = false
}

# =====================================================================
# 서브넷 (선택)
# =====================================================================
variable "subnets" {
  description = "새로 만들 서브넷. 키로 참조되며 existing_subnets 키와 겹치면 안 됨"
  type = map(object({
    cidr           = string
    zone           = string
    network_acl_no = string
    type           = optional(string, "PRIVATE")
    usage_type     = optional(string, "GEN")
    name           = optional(string)
  }))
  default  = {}
  nullable = false
}

# =====================================================================
# ACG (선택)
# =====================================================================
variable "acgs" {
  description = <<-EOT
    새로 만들 ACG. 키로 참조되며 existing_acgs 키와 겹치면 안 됨.
    규칙의 소스는 ip_block 또는 source_acg(ACG 키, 신규/기존 모두 가능) 중 하나.
    outbound 미지정 시 전체 허용(TCP/UDP/ICMP 0.0.0.0/0)이 명시적으로 적용됨.
  EOT
  type = map(object({
    name        = optional(string)
    description = optional(string, "Managed by Terraform")
    inbound = optional(list(object({
      protocol    = string
      port_range  = optional(string)
      ip_block    = optional(string)
      source_acg  = optional(string)
      description = string
    })), [])
    outbound = optional(list(object({
      protocol    = string
      port_range  = optional(string)
      ip_block    = optional(string)
      source_acg  = optional(string)
      description = string
    })))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue(flatten([
      for a in values(var.acgs) : [
        for r in concat(a.inbound, coalesce(a.outbound, [])) : (r.ip_block != null) != (r.source_acg != null)
      ]
    ]))
    error_message = "ACG 규칙마다 ip_block 또는 source_acg 중 정확히 하나만 지정해야 합니다."
  }
}

# =====================================================================
# 서버 그룹 (역할별: web, was ...)
# =====================================================================
variable "server_groups" {
  description = <<-EOT
    역할별 서버 그룹. 키가 역할명이 되어 서버 이름 = {name_prefix}-{키}-{instances} (예: svc-prd-web-01).
    subnet, acgs는 키로 참조 (subnets/existing_subnets, acgs/existing_acgs).
  EOT
  type = map(object({
    subnet              = string
    acgs                = list(string)
    server_spec_code    = string
    instances           = optional(list(string), ["01"])
    server_image_name   = optional(string, "rocky-9.6-base")
    hypervisor_type     = optional(string, "KVM")
    init_script_no      = optional(string)
    associate_public_ip = optional(bool, false)
    protect_termination = optional(bool, true)
    description         = optional(string)
    name_prefix         = optional(string)
    additional_disks = optional(map(object({
      size              = number
      volume_type       = optional(string)
      description       = optional(string)
      return_protection = optional(bool, true)
    })), {})
  }))
  default  = {}
  nullable = false
}

# =====================================================================
# 로드밸런서 (0~N개)
# =====================================================================
variable "load_balancers" {
  description = <<-EOT
    LB 목록 (0~N개). 키가 역할명 (예: waf = WAF 앞단 공인 LB, internal = WAF 뒤 내부 LB).
    - create = true  : 신규 LB 생성 (subnets 필수)
    - create = false : 기존 LB(existing_load_balancer_no)에 대상 그룹/리스너만 추가
    - vpc_no         : 대상 그룹 VPC. 미지정 시 스택 vpc_no (WAF 앞단 LB는 보안 VPC 번호 지정)
    대상 그룹의 대상은 target_server_groups(server_groups 키) + target_existing_servers(existing_servers 키)의 합.
    리스너는 target_group_key(같은 LB의 대상 그룹 키) 또는 target_group_no(기존 대상 그룹 번호) 중 하나.
  EOT
  type = map(object({
    create                    = optional(bool, true)
    existing_load_balancer_no = optional(string)
    name                      = optional(string)
    description               = optional(string, "Managed by Terraform")
    network_type              = optional(string, "PRIVATE")
    type                      = optional(string, "APPLICATION")
    subnets                   = optional(list(string), [])
    throughput_type           = optional(string, "SMALL")
    idle_timeout              = optional(number, 60)
    vpc_no                    = optional(string)

    target_groups = optional(map(object({
      name               = optional(string)
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
      target_server_groups    = optional(list(string), [])
      target_existing_servers = optional(list(string), [])
    })), {})

    listeners = optional(map(object({
      protocol             = string
      port                 = number
      target_group_key     = optional(string)
      target_group_no      = optional(string)
      ssl_certificate_no   = optional(string)
      tls_min_version_type = optional(string, "TLSV12")
      use_http2            = optional(bool)
    })), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for lb in values(var.load_balancers) : lb.create ? length(lb.subnets) > 0 : lb.existing_load_balancer_no != null])
    error_message = "create = true 이면 subnets가, create = false 이면 existing_load_balancer_no가 필요합니다."
  }
}

# =====================================================================
# DB (선택, 0~1개)
# =====================================================================
variable "database" {
  description = <<-EOT
    Cloud DB 구성. null이면 생성하지 않음. engine = "mysql" 또는 "postgresql".
    - mysql 전용: host_ip(필수), product_name
    - postgresql 전용: client_cidr(필수)
    비밀번호는 database_password 변수(TF_VAR_database_password)로 별도 주입.
  EOT
  type = object({
    engine                = string
    subnet                = string
    secondary_subnet      = optional(string)
    service_name          = optional(string)
    user_name             = string
    database_name         = string
    ha                    = bool
    multi_zone            = optional(bool, false)
    storage_encryption    = bool
    product_code          = optional(string)
    product_name          = optional(string)
    image_product_code    = optional(string)
    engine_version_code   = optional(string)
    port                  = optional(number)
    host_ip               = optional(string)
    client_cidr           = optional(string)
    backup                = optional(bool, true)
    backup_time           = optional(string)
    backup_retention_days = optional(number, 7)
  })
  default = null

  validation {
    condition     = var.database == null || contains(["mysql", "postgresql"], try(var.database.engine, ""))
    error_message = "database.engine은 mysql 또는 postgresql이어야 합니다."
  }
}

variable "database_password" {
  description = "DB 관리자 비밀번호. 반드시 TF_VAR_database_password 환경변수로 주입"
  type        = string
  default     = null
  sensitive   = true
}

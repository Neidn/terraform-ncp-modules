variable "create" {
  description = "true: ACG를 새로 생성 / false: 기존 ACG(access_control_group_no)에 규칙만 적용"
  type        = bool
  default     = true
  nullable    = false
}

variable "vpc_no" {
  description = "ACG를 생성할 VPC 번호 (create = true 일 때 필수)"
  type        = string
  default     = null
}

variable "name" {
  description = "ACG 이름. 규칙: {고객코드}-{대상}-acg (예: svc-prd-web-acg)"
  type        = string
  default     = null
}

variable "description" {
  description = "ACG 설명"
  type        = string
  default     = "Managed by Terraform"
}

variable "access_control_group_no" {
  description = "규칙을 적용할 기존 ACG 번호 (create = false 일 때 필수). 기존 규칙 전체가 이 모듈 정의로 덮어써짐에 주의"
  type        = string
  default     = null
}

variable "inbound_rules" {
  description = <<-EOT
    인바운드 규칙 목록.
    - ip_block 또는 source_access_control_group_no 중 정확히 하나를 지정
    - ICMP는 port_range를 비워둠 (null)
    - description에 허용 사유를 반드시 기재
  EOT
  type = list(object({
    protocol                       = string
    ip_block                       = optional(string)
    source_access_control_group_no = optional(string)
    port_range                     = optional(string)
    description                    = string
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for r in var.inbound_rules : contains(["TCP", "UDP", "ICMP"], r.protocol)])
    error_message = "protocol은 TCP, UDP, ICMP 중 하나여야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.inbound_rules : (r.ip_block != null) != (r.source_access_control_group_no != null)])
    error_message = "각 규칙은 ip_block 또는 source_access_control_group_no 중 정확히 하나만 지정해야 합니다."
  }
}

variable "outbound_rules" {
  description = <<-EOT
    아웃바운드 규칙 목록. 형식은 inbound_rules와 동일.
    규칙 리소스가 관리되는 경우 여기 없는 아웃바운드는 모두 차단되므로 필요한 아웃바운드를 명시할 것.
  EOT
  type = list(object({
    protocol                       = string
    ip_block                       = optional(string)
    source_access_control_group_no = optional(string)
    port_range                     = optional(string)
    description                    = string
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for r in var.outbound_rules : contains(["TCP", "UDP", "ICMP"], r.protocol)])
    error_message = "protocol은 TCP, UDP, ICMP 중 하나여야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.outbound_rules : (r.ip_block != null) != (r.source_access_control_group_no != null)])
    error_message = "각 규칙은 ip_block 또는 source_access_control_group_no 중 정확히 하나만 지정해야 합니다."
  }
}

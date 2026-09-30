variable "vpc_no" {
  description = "NACL을 생성할 VPC 번호"
  type        = string
}

variable "name" {
  description = "NACL 이름"
  type        = string
}

variable "description" {
  description = "NACL 설명"
  type        = string
  default     = "Managed by Terraform"
}

variable "inbound_rules" {
  description = <<-EOT
    인바운드 규칙 목록. 각 규칙은 ip_block 또는 deny_allow_group_no 중 정확히 하나를 지정.
    priority는 1~199, 낮을수록 먼저 평가. description에 허용/차단 사유를 반드시 기재.
  EOT
  type = list(object({
    priority            = number
    protocol            = string
    rule_action         = string
    ip_block            = optional(string)
    deny_allow_group_no = optional(string)
    port_range          = optional(string)
    description         = string
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for r in var.inbound_rules : r.priority >= 1 && r.priority <= 199])
    error_message = "priority는 1~199 사이여야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.inbound_rules : contains(["TCP", "UDP", "ICMP"], r.protocol)])
    error_message = "protocol은 TCP, UDP, ICMP 중 하나여야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.inbound_rules : contains(["ALLOW", "DROP"], r.rule_action)])
    error_message = "rule_action은 ALLOW 또는 DROP이어야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.inbound_rules : (r.ip_block != null) != (r.deny_allow_group_no != null)])
    error_message = "각 규칙은 ip_block 또는 deny_allow_group_no 중 정확히 하나만 지정해야 합니다."
  }
}

variable "outbound_rules" {
  description = "아웃바운드 규칙 목록. 형식과 제약은 inbound_rules와 동일"
  type = list(object({
    priority            = number
    protocol            = string
    rule_action         = string
    ip_block            = optional(string)
    deny_allow_group_no = optional(string)
    port_range          = optional(string)
    description         = string
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for r in var.outbound_rules : r.priority >= 1 && r.priority <= 199])
    error_message = "priority는 1~199 사이여야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.outbound_rules : contains(["TCP", "UDP", "ICMP"], r.protocol)])
    error_message = "protocol은 TCP, UDP, ICMP 중 하나여야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.outbound_rules : contains(["ALLOW", "DROP"], r.rule_action)])
    error_message = "rule_action은 ALLOW 또는 DROP이어야 합니다."
  }
  validation {
    condition     = alltrue([for r in var.outbound_rules : (r.ip_block != null) != (r.deny_allow_group_no != null)])
    error_message = "각 규칙은 ip_block 또는 deny_allow_group_no 중 정확히 하나만 지정해야 합니다."
  }
}

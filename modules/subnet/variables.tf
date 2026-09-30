variable "name" {
  description = "서브넷 이름. 규칙: {고객코드}-{용도}-subnet[-{zone}] (예: svc-prd-web-subnet)"
  type        = string
}

variable "vpc_no" {
  description = "서브넷을 생성할 VPC 번호"
  type        = string
}

variable "cidr" {
  description = "서브넷 CIDR (예: 10.0.1.0/24). VPC CIDR 범위 안이어야 함"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr는 올바른 CIDR 표기여야 합니다 (예: 10.0.1.0/24)."
  }
}

variable "zone" {
  description = "존 코드 (예: KR-1, KR-2)"
  type        = string
}

variable "network_acl_no" {
  description = "연결할 Network ACL 번호. VPC 기본 NACL을 쓰려면 기본 NACL 번호를 명시"
  type        = string
}

variable "subnet_type" {
  description = "PUBLIC 또는 PRIVATE"
  type        = string
  default     = "PRIVATE"
  nullable    = false

  validation {
    condition     = contains(["PUBLIC", "PRIVATE"], var.subnet_type)
    error_message = "subnet_type은 PUBLIC 또는 PRIVATE만 가능합니다."
  }
}

variable "usage_type" {
  description = "용도: GEN(일반), LOADB(로드밸런서 전용), BM(베어메탈), NATGW(NAT Gateway 전용)"
  type        = string
  default     = "GEN"
  nullable    = false

  validation {
    condition     = contains(["GEN", "LOADB", "BM", "NATGW"], var.usage_type)
    error_message = "usage_type은 GEN, LOADB, BM, NATGW 중 하나여야 합니다."
  }
}

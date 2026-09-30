# ---------------------------------------------------------------- 이름/개수
variable "name_prefix" {
  description = "서버 이름 prefix. 서버 이름 = {name_prefix}-{instances 원소}. 규칙: {고객코드}-{환경}-{역할} (예: svc-prd-web)"
  type        = string
}

variable "instances" {
  description = <<-EOT
    생성할 서버 번호 목록. 각 원소가 서버 키이자 이름 suffix가 된다 (예: ["01","02"]).
    중간 서버만 제거하려면 해당 번호만 목록에서 빼면 된다 (다른 서버는 영향 없음).
  EOT
  type        = list(string)
  default     = ["01"]
  nullable    = false

  validation {
    condition     = length(var.instances) > 0 && length(var.instances) == length(distinct(var.instances))
    error_message = "instances는 1개 이상이어야 하며 중복될 수 없습니다."
  }
}

variable "description" {
  description = "서버 설명"
  type        = string
  default     = null
}

# ---------------------------------------------------------------- 스펙/이미지
variable "server_spec_code" {
  description = "서버 스펙 코드 (예: c2-g3, s4-g3). KVM 기준 필수"
  type        = string
}

variable "server_image_name" {
  description = "서버 이미지 이름 (예: rocky-9.6-base, ubuntu-24.04). 공공(gov) 사이트는 이미지 이름이 다를 수 있음"
  type        = string
  default     = "rocky-9.6-base"
  nullable    = false
}

variable "hypervisor_type" {
  description = "하이퍼바이저 타입 (KVM 또는 XEN). 서버 이미지 조회와 추가 디스크에 공통 적용"
  type        = string
  default     = "KVM"
  nullable    = false

  validation {
    condition     = contains(["KVM", "XEN"], var.hypervisor_type)
    error_message = "hypervisor_type은 KVM 또는 XEN이어야 합니다."
  }
}

variable "init_script_no" {
  description = "서버 생성 시 실행할 init script 번호"
  type        = string
  default     = null
}

# ---------------------------------------------------------------- 네트워크
variable "subnet_no" {
  description = "서버를 생성할 서브넷 번호 (NIC 0번 서브넷)"
  type        = string
}

variable "access_control_group_no_list" {
  description = "NIC 0번에 연결할 ACG 번호 목록 (1~3개)"
  type        = list(string)

  validation {
    condition     = length(var.access_control_group_no_list) >= 1 && length(var.access_control_group_no_list) <= 3
    error_message = "NIC당 ACG는 1~3개여야 합니다."
  }
}

variable "additional_network_interfaces" {
  description = "NIC 1번 이후의 추가 NIC 목록 (서버마다 동일하게 생성). 대부분의 경우 비워둔다"
  type = list(object({
    subnet_no             = string
    access_control_groups = list(string)
    description           = optional(string, "secondary")
  }))
  default  = []
  nullable = false
}

variable "associate_public_ip" {
  description = "모든 서버에 공인 IP를 할당할지 여부. 일반적으로 false (LB/WAF 경유)"
  type        = bool
  default     = false
  nullable    = false
}

# ---------------------------------------------------------------- 인증/보호
variable "login_key_name" {
  description = "서버 접속용 로그인 키 이름"
  type        = string
  nullable    = false
}

variable "create_login_key" {
  description = "true 이면 login_key_name으로 로그인 키를 새로 생성 (private key는 state에 저장됨)"
  type        = bool
  default     = false
  nullable    = false
}

variable "protect_termination" {
  description = "반납(삭제) 보호 여부. 운영 서버는 true 권장"
  type        = bool
  default     = true
  nullable    = false
}

# ---------------------------------------------------------------- 추가 디스크
variable "additional_disks" {
  description = <<-EOT
    서버마다 동일하게 붙일 추가 블록 스토리지. 키가 디스크 이름 suffix가 된다.
    예: { data = { size = 100 }, log = { size = 50, volume_type = "CB1" } }
    → svc-prd-web-01-data, svc-prd-web-01-log ...
    (base_block_storage_size는 computed라 직접 지정 불가 → 추가 용량은 이 방식으로)
    파티션/마운트는 Ansible로 처리.
  EOT
  type = map(object({
    size              = number
    volume_type       = optional(string)
    description       = optional(string)
    return_protection = optional(bool, true)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for d in values(var.additional_disks) : d.size >= 10 && d.size % 10 == 0])
    error_message = "디스크 크기는 10GB 이상, 10GB 단위여야 합니다."
  }
  validation {
    condition     = alltrue([for d in values(var.additional_disks) : d.volume_type == null || contains(["SSD", "HDD", "FB1", "CB1", "FB2", "CB2"], d.volume_type)])
    error_message = "volume_type은 SSD, HDD(XEN) 또는 FB1, CB1, FB2, CB2(KVM) 중 하나여야 합니다."
  }
}

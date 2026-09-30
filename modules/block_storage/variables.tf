variable "volumes" {
  description = <<-EOT
    생성할 블록 스토리지. 키가 스토리지 이름이 된다 (3~30자, 영문 시작).
    예: { "svc-prd-web-01-data" = { server_instance_no = "123", size = 100, zone = "KR-1" } }
  EOT
  type = map(object({
    server_instance_no             = string
    size                           = number
    zone                           = string
    volume_type                    = optional(string)
    description                    = optional(string)
    snapshot_no                    = optional(string)
    return_protection              = optional(bool, true)
    stop_instance_before_detaching = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for v in values(var.volumes) : v.size >= 10 && v.size % 10 == 0])
    error_message = "size는 10GB 이상, 10GB 단위여야 합니다."
  }
  validation {
    condition     = alltrue([for k in keys(var.volumes) : length(k) >= 3 && length(k) <= 30])
    error_message = "스토리지 이름(키)은 3~30자여야 합니다."
  }
  validation {
    condition     = alltrue([for v in values(var.volumes) : v.volume_type == null || contains(["SSD", "HDD", "FB1", "CB1", "FB2", "CB2"], v.volume_type)])
    error_message = "volume_type은 SSD, HDD(XEN) 또는 FB1, CB1, FB2, CB2(KVM) 중 하나여야 합니다."
  }
}

variable "hypervisor_type" {
  description = "KVM 또는 XEN"
  type        = string
  default     = "KVM"
  nullable    = false

  validation {
    condition     = contains(["KVM", "XEN"], var.hypervisor_type)
    error_message = "hypervisor_type은 KVM 또는 XEN이어야 합니다."
  }
}

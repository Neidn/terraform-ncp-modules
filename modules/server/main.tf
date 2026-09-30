locals {
  # 서버 키("01","02"...) → 서버 이름
  servers = { for s in var.instances : s => "${var.name_prefix}-${s}" }

  # NIC 0번은 항상 subnet_no + access_control_group_no_list 로 구성
  nic_specs = concat(
    [{
      subnet_no             = var.subnet_no
      access_control_groups = var.access_control_group_no_list
      description           = "primary"
    }],
    var.additional_network_interfaces
  )

  nics = merge([
    for s, name in local.servers : {
      for idx, nic in local.nic_specs : "${s}-${idx}" => {
        server                = s
        order                 = idx
        name                  = "${name}-nic${idx}"
        subnet_no             = nic.subnet_no
        access_control_groups = nic.access_control_groups
        description           = nic.description
      }
    }
  ]...)

  disks = merge([
    for s, name in local.servers : {
      for d, disk in var.additional_disks : "${s}-${d}" => {
        server            = s
        name              = "${name}-${d}"
        size              = disk.size
        volume_type       = disk.volume_type
        description       = disk.description
        return_protection = disk.return_protection
      }
    }
  ]...)

  # create_login_key = true 이면 리소스를 참조해서 "키 생성 → 서버 생성" 순서를 보장
  login_key_name = var.create_login_key ? ncloud_login_key.this[0].key_name : var.login_key_name
}

data "ncloud_server_image_numbers" "this" {
  server_image_name = var.server_image_name

  filter {
    name   = "hypervisor_type"
    values = [var.hypervisor_type]
  }
}

resource "ncloud_login_key" "this" {
  count    = var.create_login_key ? 1 : 0
  key_name = var.login_key_name
}

resource "ncloud_network_interface" "this" {
  for_each = local.nics

  name                  = each.value.name
  subnet_no             = each.value.subnet_no
  access_control_groups = each.value.access_control_groups
  description           = each.value.description
}

resource "ncloud_server" "this" {
  for_each = local.servers

  name                = each.value
  server_image_number = data.ncloud_server_image_numbers.this.image_number_list[0].server_image_number
  server_spec_code    = var.server_spec_code
  subnet_no           = var.subnet_no
  login_key_name      = local.login_key_name
  init_script_no      = var.init_script_no
  description         = var.description

  is_protect_server_termination = var.protect_termination

  dynamic "network_interface" {
    for_each = { for k, n in local.nics : k => n if n.server == each.key }
    content {
      network_interface_no = ncloud_network_interface.this[network_interface.key].id
      order                = network_interface.value.order
    }
  }

  lifecycle {
    # 이미지 번호 조회 결과가 바뀌어도(이미지 갱신 등) 기존 서버가 재생성되지 않도록 고정
    ignore_changes = [server_image_number]
  }
}

resource "ncloud_public_ip" "this" {
  for_each = var.associate_public_ip ? local.servers : {}

  server_instance_no = ncloud_server.this[each.key].instance_no
  description        = "${each.value}-pip"
}

resource "ncloud_block_storage" "this" {
  for_each = local.disks

  server_instance_no = ncloud_server.this[each.value.server].instance_no
  name               = each.value.name
  size               = each.value.size
  volume_type        = each.value.volume_type
  description        = each.value.description
  zone               = ncloud_server.this[each.value.server].zone
  hypervisor_type    = var.hypervisor_type
  return_protection  = each.value.return_protection
}

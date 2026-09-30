# 기존 서버(모듈 밖에서 만든 서버)에 디스크를 붙일 때 사용하는 단독 모듈.
# 이 모듈로 서버를 만드는 경우에는 server 모듈의 additional_disks를 사용한다.

resource "ncloud_block_storage" "this" {
  for_each = var.volumes

  server_instance_no = each.value.server_instance_no
  name               = each.key
  size               = each.value.size
  volume_type        = each.value.volume_type
  description        = each.value.description
  zone               = each.value.zone
  hypervisor_type    = var.hypervisor_type
  snapshot_no        = each.value.snapshot_no
  return_protection  = each.value.return_protection

  stop_instance_before_detaching = each.value.stop_instance_before_detaching
}

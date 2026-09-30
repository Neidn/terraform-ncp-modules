resource "ncloud_subnet" "this" {
  name           = var.name
  vpc_no         = var.vpc_no
  subnet         = var.cidr
  zone           = var.zone
  network_acl_no = var.network_acl_no
  subnet_type    = var.subnet_type
  usage_type     = var.usage_type
}

# v0.x 리소스 주소(ncloud_subnet.subnet) → v1 주소로 state 자동 이동
moved {
  from = ncloud_subnet.subnet
  to   = ncloud_subnet.this
}

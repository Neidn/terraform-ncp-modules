terraform {
  required_version = ">= 1.5.0"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "~> 4.0"
    }
  }
}

# 인증키는 코드/tfvars에 두지 않는다.
#   export NCLOUD_ACCESS_KEY=...  NCLOUD_SECRET_KEY=...
provider "ncloud" {
  region      = "KR"
  site        = "gov" # 민간: "public"
  support_vpc = true
}

terraform {
  # optional() 기본값(1.3+), moved/import 블록 활용(1.5+) 기준
  required_version = ">= 1.5.0"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = ">= 3.0"
    }
  }
}

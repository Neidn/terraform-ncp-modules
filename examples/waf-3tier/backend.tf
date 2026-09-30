# backend 블록에는 변수를 쓸 수 없다. 인증은 환경변수로:
#   export AWS_ACCESS_KEY_ID=$NCLOUD_ACCESS_KEY AWS_SECRET_ACCESS_KEY=$NCLOUD_SECRET_KEY
terraform {
  backend "s3" {
    bucket = "<STATE_BUCKET>"
    key    = "<SERVICE>/terraform.tfstate"
    region = "KR"

    endpoints = {
      s3 = "https://kr.object.gov-ncloudstorage.com" # 민간: https://kr.object.ncloudstorage.com
    }

    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true

    # NCP Object Storage에서 lockfile 동작이 검증되지 않아 비활성화.
    # 동시 apply 방지는 운영 규칙(1 서비스 1 작업자)으로 관리.
    use_lockfile = false
  }
}

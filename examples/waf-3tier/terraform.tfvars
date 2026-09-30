# 표준 구성: 인터넷 → [WAF 앞단 공인 LB] → WAF 서버 → [내부 LB] → web → was → DB
# 번호(<...>)는 모두 예시 placeholder. 실제 값으로 교체.

name_prefix    = "svc-prd"
vpc_no         = "<SERVICE_VPC_NO>"
login_key_name = "<LOGIN_KEY>"

# ---------------------------------------------------------------- 기존 리소스 (키 → 번호)
existing_subnets = {
  waf-lb = "<WAF_LB_SUBNET_NO>" # 보안 VPC의 WAF LB용 공인 서브넷
}

existing_servers = {
  waf01 = "<WAF01_INSTANCE_NO>"
  waf02 = "<WAF02_INSTANCE_NO>"
}

# ---------------------------------------------------------------- 신규 서브넷
subnets = {
  lb  = { cidr = "10.10.1.0/24", zone = "KR-1", network_acl_no = "<NACL_NO>", usage_type = "LOADB" }
  web = { cidr = "10.10.11.0/24", zone = "KR-1", network_acl_no = "<NACL_NO>" }
  was = { cidr = "10.10.12.0/24", zone = "KR-1", network_acl_no = "<NACL_NO>" }
  db  = { cidr = "10.10.21.0/24", zone = "KR-1", network_acl_no = "<NACL_NO>" }
}

# ---------------------------------------------------------------- ACG
acgs = {
  web = {
    inbound = [
      { protocol = "TCP", port_range = "80", ip_block = "10.10.1.0/24", description = "HTTP from internal LB subnet" },
      { protocol = "TCP", port_range = "22", ip_block = "<BASTION_IP>/32", description = "SSH from bastion" },
    ]
  }
  was = {
    inbound = [
      { protocol = "TCP", port_range = "8080", source_acg = "web", description = "WAS from web tier" },
      { protocol = "TCP", port_range = "22", ip_block = "<BASTION_IP>/32", description = "SSH from bastion" },
    ]
  }
}

# ---------------------------------------------------------------- 서버
server_groups = {
  web = {
    subnet           = "web"
    acgs             = ["web"]
    server_spec_code = "c2-g3"
    instances        = ["01", "02"]
  }
  was = {
    subnet           = "was"
    acgs             = ["was"]
    server_spec_code = "c4-g3"
    instances        = ["01", "02"]
    additional_disks = {
      data = { size = 100 }
    }
  }
}

# ---------------------------------------------------------------- LB (WAF 앞/뒤 2개 신규 생성)
load_balancers = {
  # WAF 앞단: 인터넷 → WAF 서버
  waf = {
    network_type = "PUBLIC"
    subnets      = ["waf-lb"]
    vpc_no       = "<SECURITY_VPC_NO>" # 대상(WAF 서버)이 보안 VPC에 있음
    description  = "svc.example.go.kr"
    target_groups = {
      http = {
        protocol                = "HTTP"
        port                    = 80
        health_check            = { protocol = "HTTP", port = 18088, url_path = "/healthcheck" }
        target_existing_servers = ["waf01", "waf02"]
      }
    }
    listeners = {
      https = { protocol = "HTTPS", port = 443, target_group_key = "http", ssl_certificate_no = "<CERT_NO>" }
      http  = { protocol = "HTTP", port = 80, target_group_key = "http" }
    }
  }

  # WAF 뒤: WAF 서버 → web (이 LB의 domain을 WAF 백엔드로 등록)
  internal = {
    network_type = "PRIVATE"
    subnets      = ["lb"]
    description  = "internal lb for svc.example.go.kr"
    target_groups = {
      web = {
        protocol             = "HTTP"
        port                 = 80
        health_check         = { protocol = "HTTP", url_path = "/" }
        target_server_groups = ["web"]
      }
    }
    listeners = {
      http = { protocol = "HTTP", port = 80, target_group_key = "web" }
    }
  }
}

# ---------------------------------------------------------------- DB
database = {
  engine             = "mysql"
  subnet             = "db"
  user_name          = "svcadmin"
  database_name      = "svcdb"
  host_ip            = "10.10.12.%" # WAS 서브넷만
  product_name       = "vCPU 2EA, Memory 4GB"
  ha                 = true
  storage_encryption = true
}

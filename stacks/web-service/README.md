# stacks/web-service

표준 서비스 구성을 tfvars만으로 조합하는 스택.

```
인터넷 → [LB: waf] → WAF 서버(보안 VPC, 기존) → [LB: internal] → web → was → DB
```

스택은 **VPC를 만들지 않는다.** 기존 VPC 번호를 받아 그 안에 서브넷·ACG·서버·LB·DB를 만든다.

## 핵심 규칙: 모든 참조는 "키"로

- 스택 안에서 서브넷·ACG·서버는 번호가 아니라 **키**로 참조한다.
- 콘솔에서 만들었거나 다른 state에 있는 리소스는 `existing_subnets` / `existing_acgs` / `existing_servers`에
  `키 = 번호`로 한 번만 등록하고, 나머지는 전부 키로 쓴다.
- 기존 ACG는 **참조만** 한다. 스택은 기존 ACG의 규칙을 수정하지 않는다
  (ACG 규칙 리소스는 규칙 전체를 덮어쓰기 때문).

## LB 구성 패턴 (0~N개)

`load_balancers`의 각 항목이 LB 하나다. 키는 역할명(`waf`, `internal` 등).

### A. WAF 앞/뒤 LB 모두 신규 (서비스별로 앞/뒤 LB를 각각 생성하는 형태) → `examples/waf-3tier/terraform.tfvars`

### B. 공용 WAF LB 재사용 + 리스너/대상 그룹만 추가

```hcl
load_balancers = {
  waf = {
    create                    = false
    existing_load_balancer_no = "<SHARED_WAF_LB_NO>"
    vpc_no                    = "<SECURITY_VPC_NO>"
    target_groups = {
      https8443 = {
        protocol                = "HTTP"
        port                    = 8443
        health_check            = { protocol = "HTTP", port = 18088, url_path = "/healthcheck" }
        target_existing_servers = ["waf01", "waf02"]
      }
    }
    listeners = {
      https8443 = { protocol = "HTTPS", port = 8443, target_group_key = "https8443", ssl_certificate_no = "<CERT_NO>" }
    }
  }
  internal = { ... } # 내부 LB는 신규
}
```

기존 대상 그룹에 연결만 할 때는 `target_group_key` 대신 `target_group_no = "<기존 TG 번호>"`.

### C. 기존 LB의 "이미 있는 리스너"를 수정

같은 포트로 리스너를 정의만 하면 포트 중복으로 실패한다. 먼저 루트에서 import 후 수정:

```hcl
# 루트 모듈의 imports.tf
import {
  to = module.service.module.lb["waf"].ncloud_lb_listener.this["https"]
  id = "<LISTENER_IMPORT_ID>" # 형식은 ncloud provider 문서의 ncloud_lb_listener Import 항목 확인
}
```

import 후 첫 plan은 **변경 0건**이 되도록 기존 값을 tfvars에 맞추고, 그 다음 수정한다.

### D. LB 없음

`load_balancers`를 비워두면 된다 (기본값 `{}`).

## WAF 연동 순서

1. apply 후 `terraform output load_balancers`에서 `internal.domain` 확인
2. WAF 콘솔에서 해당 서비스의 백엔드(원본 서버)로 internal LB 도메인 등록 (Terraform 범위 밖)
3. `waf` LB 리스너 → WAF 서버 → internal LB → web 순으로 헬스체크 확인

## 알아둘 점

- ACG `outbound`를 생략하면 전체 허용 규칙이 **명시적으로** 들어간다. 빈 목록 `[]`을 주면 아웃바운드 전체 차단.
- Cloud DB는 자체 ACG를 자동 생성한다. web/was → DB 허용은 DB 쪽 ACG에서 별도로 관리해야 한다.
- 서버 이름 = `{name_prefix}-{그룹키}-{번호}`, LB 이름 = `{name_prefix}-{LB키}-lb`,
  대상 그룹 = `{name_prefix}-{LB키}-{TG키}-tg`. NCP 이름 길이 제한(대부분 30자)에 주의해 키는 짧게.
  기존 리소스 이관 시에는 `name`을 명시해 기존 이름을 유지한다.
- 추가 디스크의 파티션·마운트, OS 설정은 Ansible에서 처리한다 (`ansible_inventory` 출력 사용).

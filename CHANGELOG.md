# CHANGELOG

## v1.0.0 (BREAKING)

기존 모듈을 표준화한 첫 태그. **v0.x 모듈을 쓰던 루트는 ref를 올리기 전에 아래 이관을 먼저 확인**하고,
plan에서 destroy/replace가 0건인지 확인한 뒤 apply한다.

### 버그 수정
- `postgresql`: port 기본값 5432가 validation(10000~20000)에 걸려 항상 실패 → 5432 허용
- `mysql`: `product_code`에 스펙 이름("vCPU 2EA, Memory 4GB")이 들어가던 문제 → 조회 결과 코드 사용
- `lb`: `optional()` 속성에 `try(x, 기본값)`을 써서 기본값이 적용되지 않던 문제 → 타입 선언의 optional 기본값으로 변경
- `server`: `create_login_key = true`일 때 로그인키 생성 전에 서버 생성이 시도될 수 있던 의존성 누락 수정

### 변경 사항과 이관 방법

| 모듈 | 변경 | 기존 state 영향 | 조치 |
|---|---|---|---|
| subnet | 변수 `subnet` → `cidr`, 출력 `subnet_id` 제거 | 주소 자동 이동(moved) | 호출부 변수명만 수정 |
| acg | acg_rules 통합, `create` 플래그 추가 | 주소 자동 이동(moved) | acg_rules 사용처는 `source`를 acg로, `create = false` 추가. 규칙 리소스 주소가 같아 추가 이동 불필요 |
| nacl | versions.tf 추가, 규칙별 ip_block/deny_allow_group_no 상호배타 검증 | 없음 | - |
| lb | `create` 플래그, 리스너 `target_group_no` 지원, TLS 기본 TLSV12 | `ncloud_lb` 주소 자동 이동 | **기존 리스너가 TLSV10/11이면 tfvars에 명시**해야 변경 없음 |
| server | `count` → `for_each`(instances), 리소스명 `server`→`this`, NIC 입력 구조 변경 | **자동 이동 불가** | 루트에 moved 블록 필요 (아래 예시) |
| block_storage | `count` → `for_each`(volumes map) | **자동 이동 불가** | 루트에 moved 블록 필요 |
| mysql | 변수명 통일(`is_ha`→`ha` 등), `service_name`·`host_ip`·`database_name`·`storage_encryption` 필수 | 주소 자동 이동(moved) | 기존 값과 동일하게 지정: `database_name = <기존 user_name>`, `host_ip = "%"`, `service_name = <기존 server_name>` |
| postgresql | 변수명 통일, `product_code`·`storage_encryption`·`ha` 필수 | 주소 자동 이동(moved) | 기존 state의 product_code를 그대로 지정 (`terraform state show`로 확인) |

### server 모듈 이관 예시 (루트 모듈에 추가)

```hcl
# v0.x: name_prefix = "svc-prd-web", server_count = 2
# v1  : name_prefix = "svc-prd-web", instances = ["01", "02"]
moved {
  from = module.web.ncloud_server.server[0]
  to   = module.web.ncloud_server.this["01"]
}
moved {
  from = module.web.ncloud_server.server[1]
  to   = module.web.ncloud_server.this["02"]
}
moved {
  from = module.web.ncloud_network_interface.server_nic["0-0"]
  to   = module.web.ncloud_network_interface.this["01-0"]
}
moved {
  from = module.web.ncloud_network_interface.server_nic["1-0"]
  to   = module.web.ncloud_network_interface.this["02-0"]
}
# 공인 IP를 쓰던 경우 ncloud_public_ip.public_ip[n] → ncloud_public_ip.this["0n"] 도 동일하게
```

주의: v0.x에서 `server_count = 1`이면 서버 이름이 `name_prefix` 그대로(번호 없음)였다.
v1은 항상 `{name_prefix}-{번호}`이므로, 이름이 바뀌어 재생성되지 않게 하려면
`name_prefix`를 기존 이름에서 마지막 `-번호`를 뗀 값으로, `instances`를 그 번호로 맞춰야 한다.
기존 이름에 번호가 없다면 이관하지 말고 v0.x ref를 유지한다.
NIC 이름·설명도 v1 규칙으로 바뀌므로 plan에서 in-place 변경이 나오는지 확인할 것.

# terraform-ncp-modules

NCP(공공/민간) 표준 Terraform 모듈. 고객사 repo는 이 repo를 **태그로 고정**해서 참조한다.

```hcl
module "service" {
  source = "git::https://<GITEA_HOST>/infra/terraform-ncp-modules.git//stacks/web-service?ref=v1.0.0"
  # ...
}
```

## 구조

| 경로 | 역할 |
|---|---|
| `stacks/web-service` | **기본 진입점.** WAF 경유 LB → web/WAS → DB 구성을 tfvars만으로 조합 |
| `modules/subnet` | 서브넷 |
| `modules/nacl` | Network ACL + 규칙 |
| `modules/acg` | ACG 생성 또는 기존 ACG에 규칙 적용 (v0.x의 acg + acg_rules 통합) |
| `modules/server` | 서버 + NIC + 공인IP + 서버별 추가 디스크 |
| `modules/block_storage` | 모듈 밖 기존 서버에 디스크 추가 |
| `modules/lb` | LB 생성 또는 기존 LB 재사용 + 대상 그룹 + 리스너 |
| `modules/mysql`, `modules/postgresql` | Cloud DB |
| `examples/waf-3tier` | 표준 구성 예제 (고객사 repo 템플릿) |
| `docs/AI_RULES.md` | AI(Claude)가 이 repo로 작업할 때의 규칙 → 스킬로 옮길 원본 |

## 공통 규칙

- Terraform `>= 1.5`, provider `NaverCloudPlatform/ncloud` (루트에서 `~> 4.0` 고정)
- 모든 모듈은 `versions.tf` / `variables.tf` / `outputs.tf` / `main.tf` 구성, 줄바꿈 LF
- 식별자 출력은 `<리소스>_no` (예: `subnet_no`, `load_balancer_no`)
- 불리언은 `is_` 접두어 없이 (`ha`, `backup`, `storage_encryption`)
- 되돌리기 어려운 값(`ha`, `storage_encryption` 등)은 기본값 없이 명시 필수
- 기본값이 있는 변수는 `nullable = false` → 상위에서 null을 넘겨도 기본값 적용
- 인증키·비밀번호는 코드/tfvars 금지, 환경변수만 (`NCLOUD_*`, `TF_VAR_*`)

## 버전 관리

- 태그: `vMAJOR.MINOR.PATCH`. 주소/변수명이 바뀌는 변경은 MAJOR
- 변경 내역과 이관 방법은 `CHANGELOG.md`
- 모듈 수정 후 `terraform fmt -recursive` / 예제 디렉토리에서 `terraform validate` 확인 후 태그

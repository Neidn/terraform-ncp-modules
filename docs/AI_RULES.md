# AI 작업 규칙 (Claude 스킬 원본)

이 repo와 고객사 Terraform repo를 AI가 다룰 때 지켜야 할 규칙.

## 작성 범위
1. 새 서비스는 `stacks/web-service`를 태그 고정 git source로 호출하고 **tfvars만 작성**한다.
2. 스택으로 표현 가능한 것을 raw `ncloud_*` 리소스로 쓰지 않는다.
3. 스택/모듈로 불가능한 요구는 raw 리소스로 작성하되, 파일 상단 주석에 사유를 적고 사람에게 모듈화 여부를 묻는다.
4. 번호(서브넷/ACG/서버/LB)는 `existing_*` 맵에만 쓰고, 나머지는 키로 참조한다.

## 금지
- 인증키·비밀번호를 코드/tfvars/출력에 쓰지 않는다 (`NCLOUD_*`, `TF_VAR_*` 환경변수).
- `terraform apply`, `destroy`, `state rm`, `import`를 AI가 실행하지 않는다. 명령은 제안만 한다.
- `timestamp()`를 이름·태그 등 리소스 속성에 쓰지 않는다 (매 plan마다 변경 발생).
- 기존 ACG/NACL에 규칙 리소스를 붙이지 않는다 (규칙 전체가 덮어써짐). 필요하면 사람에게 확인.

## NCP 주의사항
- `base_block_storage_size`는 computed → 추가 용량은 `additional_disks`(또는 block_storage 모듈).
- Cloud DB의 `storage_encryption`, `ha` 등은 변경 시 재생성 → 기존 값 확인 없이 바꾸지 않는다.
- LB 리스너 TLS는 TLSV12 기본. 기존 리소스 이관 시에만 기존 값 유지.
- 공공(gov) 사이트는 endpoint와 이미지 이름이 민간과 다를 수 있다.
- 파일은 LF 줄바꿈.

## 변경 검증 (사람이 실행)
1. `make plan` → 출력 끝의 `⚠️ DELETE` 목록 확인
2. 이관 작업은 "to move만 있고 add/change/destroy 0건"이 목표
3. destroy/replace가 있으면 apply 전 사람에게 사유 설명

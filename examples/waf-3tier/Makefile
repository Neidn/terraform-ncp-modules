# 안전 원칙: plan 파일로만 apply, destroy 타깃 없음
TF ?= terraform

.PHONY: check-env init fmt validate plan show apply output

check-env:
	@test -n "$$NCLOUD_ACCESS_KEY" || (echo "NCLOUD_ACCESS_KEY 미설정" && exit 1)
	@test -n "$$NCLOUD_SECRET_KEY" || (echo "NCLOUD_SECRET_KEY 미설정" && exit 1)

init: check-env
	AWS_ACCESS_KEY_ID=$$NCLOUD_ACCESS_KEY AWS_SECRET_ACCESS_KEY=$$NCLOUD_SECRET_KEY $(TF) init

fmt:
	$(TF) fmt -recursive

validate:
	$(TF) validate

plan: check-env validate
	AWS_ACCESS_KEY_ID=$$NCLOUD_ACCESS_KEY AWS_SECRET_ACCESS_KEY=$$NCLOUD_SECRET_KEY $(TF) plan -out=tfplan
	$(TF) show -json tfplan | jq -r '.resource_changes[] | select(.change.actions | index("delete")) | "⚠️  DELETE: " + .address'

show:
	$(TF) show tfplan

apply: check-env
	@test -f tfplan || (echo "tfplan 없음. make plan 먼저" && exit 1)
	AWS_ACCESS_KEY_ID=$$NCLOUD_ACCESS_KEY AWS_SECRET_ACCESS_KEY=$$NCLOUD_SECRET_KEY $(TF) apply tfplan
	rm -f tfplan

output:
	$(TF) output -json

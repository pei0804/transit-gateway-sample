.PHONY: docs
docs:
	docker run --rm \
      -v $(PWD):/data \
      cytopia/terraform-docs \
      terraform-docs-012 --sort-inputs-by-required --with-aggregate-type-defaults md . > README.md.sample

.PHONY: init
init:
	terraform $@

.PHONY: plan
plan: init
	terraform $@

.PHONY: apply
apply: init
	terraform $@

.PHONY: destroy
destroy:
	terraform $@

.PHONY: fmt
fmt:
	terraform $@

.PHONY: help
help:
	cat Makefile

create-key:
	ssh-keygen -t rsa -b 4096 -C '' -N '' -f ssh-keygen -t rsa -f mykey
	chmod 400 mykey

ssh:
	ssh -i mykey ec2-user@$(IP)
EXAMPLE ?= complete

.PHONY: help init plan apply destroy validate fmt docs clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform (EXAMPLE=complete|minimal)
	cd examples/$(EXAMPLE) && terraform init

plan: ## Plan changes (EXAMPLE=complete|minimal)
	cd examples/$(EXAMPLE) && terraform plan

apply: ## Apply changes (EXAMPLE=complete|minimal)
	cd examples/$(EXAMPLE) && terraform apply

destroy: ## Destroy all resources (EXAMPLE=complete|minimal)
	cd examples/$(EXAMPLE) && terraform destroy

validate: ## Validate all modules and examples
	@for dir in modules/*/; do \
		echo "=== $$dir ===" && \
		(cd "$$dir" && terraform init -backend=false -no-color 2>/dev/null && terraform validate -no-color) || exit 1; \
	done
	@for dir in examples/*/; do \
		echo "=== $$dir ===" && \
		(cd "$$dir" && terraform init -backend=false -no-color 2>/dev/null && terraform validate -no-color) || exit 1; \
	done

fmt: ## Format all Terraform files
	terraform fmt -recursive .

fmt-check: ## Check formatting without changes
	terraform fmt -recursive -check .

docs: ## Generate README.md for each module using terraform-docs
	@for dir in modules/*/; do \
		echo "Generating docs for $$dir" && \
		terraform-docs markdown table "$$dir" > "$$dir/README.md"; \
	done
	@echo "Done. READMEs generated in each module."

clean: ## Remove .terraform directories and lock files
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "Cleaned .terraform directories and lock files."

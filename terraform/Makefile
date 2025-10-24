AWS_VAULT_PROFILE ?= default

.PHONY: init plan apply destroy all

all: init plan apply

init:
	aws-vault exec $(AWS_VAULT_PROFILE) -- terraform init

plan:
	aws-vault exec $(AWS_VAULT_PROFILE) -- terraform plan -var-file=terraform.tfvars

apply:
	aws-vault exec $(AWS_VAULT_PROFILE) -- terraform apply -var-file=terraform.tfvars -auto-approve

destroy:
	aws-vault exec $(AWS_VAULT_PROFILE) -- terraform destroy -var-file=terraform.tfvars -auto-approve

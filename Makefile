.PHONY: init prep plan deploy destroy lint

init:
	@tofu init

plan: prep
	@tofu plan -var-file=environments/$(ENV).tfvars

deploy: prep
	@tofu apply -var-file=environments/$(ENV).tfvars -auto-approve

destroy: prep
	@tofu destroy -var-file=environments/$(ENV).tfvars

lint:
	@tofu fmt -write=true -recursive
save:
	@tofu plan -out=plan.out -var-file=environments/$(ENV).tfvars

IMAGE-NAME="dbt-serverless"

infra-get:
	cd infrastructure && terraform get;

infra-init: infra-get
	cd infrastructure && terraform init -upgrade;

infra-plan: infra-init
	cd infrastructure && terraform plan;

infra-apply: infra-plan
	cd infrastructure && terraform apply;

infra-destroy:
	cd infrastructure && terraform destroy;

docker-build:
	docker build --rm -t $IMAGE_NAME:latest .

run-dbt-example-docker:
	bash utils/run_container_locally.sh example

push-to-ecr:
	bash utils/push_to_ecr.sh

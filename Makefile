IMAGE_NAME="dbt-serverless"
AWS_ACCOUNT_ID=

install:
	pip install -r requirements.txt

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
	@docker build --rm -t ${IMAGE_NAME}:latest .

run-dbt-example-docker:
	bash utils/run_container_locally.sh example

push-to-ecr:
	bash utils/push_to_ecr.sh ${AWS_ACCOUNT_ID}

upload-lambda-python-3.7-postgres:
	cd utils/lambda_layer_python_3.7 && bash upload_layer.sh postgres

postgres-up: postgres-down
	docker-compose up -d

postgres-down:
	docker-compose down

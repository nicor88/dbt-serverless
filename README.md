# dbt-serverless
Run dbt serverless in the Cloud (AWS)

## Requirements
* aws credentials configured in `~/.aws/credentials`
* aws cli
    <pre
    pip install awscli
    </pre>
* terraform


## Deploy
The infrastructure is based on terraform.
I setup a terraform backend to keep terraform state. The backend is based an S3 bucket that was created manually.
You can create an S3 bucket simply running:
<pre>
aws s3api create-bucket --bucket nicor88-eu-west-1-terraform --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1
</pre>
Remember to change the name of the S3 bucket inside `infrastructure/provider.tf` before running the following commands:
<pre>
export AWS_PROFILE=your_profile
make infra-plan
make infra-apply
</pre>

After the infra is created correctly, you can push an new image to the ECR repository running:
<pre>
make push-to-ecr AWS_ACCOUNT_ID=your_account_id
</pre>

### Note
Currently Aurora Postgres is only accessible inside the VPC.
I create a Network load balancer, to connect to the DB from everywhere, but you need to get the Private IP of Aurora Endpoint.
You can simply run:
<pre>
nslookup your_aurora_enpoint
# returned from the terraform outputs
</pre>
Then you need to replace the 2 variables:
* autora_postgres_serverless_private_ip_1
* autora_postgres_serverless_private_ip_2

and apply again the changes with the command `make infra-apply`

## Infrastructure

### AWS Step Function

#### Input example

<pre>
{
  "commands1": [
    "dbt",
    "run",
    "--models"
    "example"
  ],
  {
  "commands2": [
    "dbt",
    "run",
  	"--models"
    "just_another_example"
  ]
}
}
</pre>

## TODO
* test schedule of only ECS container,  [terraform-reference](https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_target.html#example-ecs-run-task-with-role-and-task-override-usage)

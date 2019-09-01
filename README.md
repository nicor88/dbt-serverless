# dbt-serverless
Run dbt serverless in the Cloud (AWS)

## Requirements
* aws credentials configured in `~/.aws/credentials`
* terraform
    * MacOs


## AWS Step Function

### Input example

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

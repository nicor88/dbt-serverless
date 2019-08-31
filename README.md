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
  "commands": [
    "dbt",
    "run"
  ]
}
</pre>

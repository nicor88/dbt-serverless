
## Definition
<pre>
{
 "StartAt": "dbt_test",
 "States": {
   "dbt_test": {
     "Type": "Task",
     "Resource": "arn:aws:states:::ecs:runTask.sync",
     "Parameters": {
                "Cluster": "arn:aws:ecs:us-east-1:account_id:cluster/dbt",
                "TaskDefinition": "dbt",
                "LaunchType": "FARGATE",
                "NetworkConfiguration": { "awsvpcConfiguration": {
                	"subnets": ["subnet-1"],
                	"assignPublicIp": "ENABLED",
                	"securityGroups": ["sg-1"]
            		}},
                "Overrides": {
                    "ContainerOverrides": [
                        {
                            "Name": "dbt",
                            "Command.$": "$.commands"
                        }
                    ]
                }
            },
     "End": true
    }
  }
}

</pre>

### Input

<pre>
{
  "commands": [
    "dbt",
    "run",
    "--models",
    "example"
  ]
}
</pre>
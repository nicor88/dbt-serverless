{
  "StartAt": "first_task",
  "States": {
    "first_task": {
      "Type": "Task",
      "Resource": "arn:aws:states:::ecs:runTask.sync",
      "Parameters": {
        "Cluster": "${ecs_cluster}",
        "TaskDefinition": "${ecs_task_name}",
        "LaunchType": "FARGATE",
        "NetworkConfiguration": {
          "AwsvpcConfiguration": {
            "Subnets": ["${subnet_1}", "${subnet_2}", "${subnet_3}"],
            "AssignPublicIp": "ENABLED",
            "SecurityGroups": ["${security_group_1}"]
          }
        },
        "Overrides": {
          "ContainerOverrides": [
            {
              "Name": "dbt",
              "Command.$": "$.commands"
            }
          ]
        }
      },
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "FailureExample"
        }
      ],
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": ${retry_seconds},
          "BackoffRate": ${retry_backoff},
          "MaxAttempts": ${retry_attempts}
        }
      ],
      "End": true
    },
    "FailState": {
      "Type": "Fail"
    }
  }
}

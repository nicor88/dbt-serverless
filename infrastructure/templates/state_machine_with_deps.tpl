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
              "Command.$": "$.commands1"
            }
          ]
        }
      },
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": ${retry_seconds},
          "BackoffRate": ${retry_backoff},
          "MaxAttempts": ${retry_attempts}
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "FailureNotifier",
          "ResultPath": null
        }
      ],
      "Next": "second_task",
      "ResultPath": "$.task_1"
    },
    "second_task": {
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
              "Command.$": "$.commands2"
            }
          ]
        }
      },
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": ${retry_seconds},
          "BackoffRate": ${retry_backoff},
          "MaxAttempts": ${retry_attempts}
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "FailureNotifier",
          "ResultPath": null
        }
      ],
      "ResultPath": "$.task_2",
      "End": true
    },
    "FailureNotifier": {
      "Type": "Pass",
      "Next": "Failure",
      "ResultPath": "$.notifier"
    },
    "Failure": {
      "Type": "Fail"
    }
  }
}

resource "aws_ecr_repository" "docker_repository" {
  name = "${var.project}"
}

resource "aws_ecr_lifecycle_policy" "docker_repository_lifecycly" {
  repository = "${aws_ecr_repository.docker_repository.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep only the latest 5 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.project}"
  retention_in_days = 5
}

resource "aws_iam_role" "ecs_task_iam_role" {
  name = "${var.project}-ecs-task-role"
  description = "Allow ECS tasks to access AWS resources"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.project}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = "${aws_iam_role.ecs_task_iam_role.name}"
  policy_arn = "${aws_iam_policy.ecs_task_policy.arn}"
}

resource "aws_ecs_task_definition" "dbt_task_definition" {
  family = "${var.project}-task"
  network_mode = "awsvpc"
  execution_role_arn = "${aws_iam_role.ecs_task_iam_role.arn}"
  requires_compatibilities = ["FARGATE"]
  cpu = "256" # the valid CPU amount for 2 GB is from from 256 to 1024
  memory = "512" #512/256 or 2048/1024
  container_definitions = <<EOF
[
  {
    "name": "dbt",
    "image": ${replace(jsonencode("${aws_ecr_repository.docker_repository.repository_url}:latest"), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")} ,
    "essential": true,
    "environment": [
      {
        "name": "DB_HOST",
        "value": ${replace(jsonencode("${aws_rds_cluster.postgres_severless.endpoint}"), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")}
      },
      {
        "name": "DB_PORT",
        "value": "5432"
      },
      {
        "name": "DB_USER",
        "value": ${replace(jsonencode("${var.master_username}"), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")}
      },
      {
        "name": "DB_PASSWORD",
        "value": ${replace(jsonencode("${random_string.postgres_severless_master_password.result}"), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")}
      },
      {
        "name": "DB_NAME",
        "value": ${replace(jsonencode("${var.database_name}"), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")}
      },
      {
        "name": "DB_SCHEMA",
        "value": ${replace(jsonencode("${var.dbt_default_schema}"), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")}
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${var.project}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "dbt"
        }
    }
  }
]
EOF
}

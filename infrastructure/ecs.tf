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
  name = "/aws/ecs/${var.project}"
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
  name        = "${var.project}-ecs-policy"

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

resource "aws_iam_role_policy_attachment" "attach_policy_ecs_task_role" {
  role       = "${aws_iam_role.ecs_task_iam_role.name}"
  policy_arn = "${aws_iam_policy.ecs_task_policy.arn}"
}

data "template_file" "ecs_dbt_task_definition" {
  template = "${file("templates/ecs_dbt.tpl")}"

  vars {
    container_name="dbt"
    image="${aws_ecr_repository.docker_repository.repository_url}"
    image_version = "latest"
    essential="true"

    # db config
    db_host="${aws_rds_cluster.postgres_severless.endpoint}"
    db_port="${var.db_port}"
    db_user="${var.master_username}"
    db_password="${random_string.postgres_severless_master_password.result}"
    db_name="${var.database_name}"
    db_schema="${var.dbt_default_schema}"

    # logs
    log_group="/aws/ecs/${var.project}"
    log_region="${var.aws_region}"
    log_stream_prefix="dbt"

  }
}

resource "aws_ecs_task_definition" "dbt_task_definition" {
  family = "${var.project}-task"
  network_mode = "awsvpc"
  execution_role_arn = "${aws_iam_role.ecs_task_iam_role.arn}"
  requires_compatibilities = ["FARGATE"]
  cpu = "256" # the valid CPU amount for 2 GB is from from 256 to 1024
  memory = "512" #512/256 or 2048/1024
  container_definitions = "${data.template_file.ecs_dbt_task_definition.rendered}"
}

resource "aws_iam_role" "events_scheduler" {
  name = "${var.project}-events-scheduler"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "events_scheduler_policy" {
  name = "ecs_events_run_task_with_any_role"
  role = "${aws_iam_role.events_scheduler.id}"

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "states:StartExecution"
            ],
            "Resource": "arn:aws:states:*:*:*"
        }
    ]
}
DOC
}

resource "aws_cloudwatch_event_rule" "state_machine_trigger" {
  name = "${var.project}-state-machine-schedule"
  schedule_expression = "cron(0 * * * ? *)" # "rate(60 minutes)"
  is_enabled = true
}

resource "aws_cloudwatch_event_target" "state_machine_target" {
  rule = "${aws_cloudwatch_event_rule.state_machine_trigger.id}"
  arn = "${aws_sfn_state_machine.sfn_state_machine_with_no_deps.id}"
  role_arn = "${aws_iam_role.events_scheduler.arn}"
  input = <<EOF
  {
  "commands": ["dbt", "run"]
  }
EOF
}

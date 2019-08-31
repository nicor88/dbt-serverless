resource "random_string" "postgres_severless_master_password" {
  length = 32
  upper = true
  number = true
  special = false
}

resource "aws_db_subnet_group" "postgres_severless" {
  name        = "postgres-serverless"
  description = "Subnet group for postgres serverless"
  subnet_ids  = ["${aws_subnet.public.*.id}"]

  tags {
    Name        = "postgres-serverless-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "postgres_severless" {
  name   = "postgres-serverless-pg"
  family = "aurora-postgresql10"
  description = "Aurora Postgres Serverless parameter group"
}

resource "aws_rds_cluster" "postgres_severless" {
  cluster_identifier      = "dbt-postgres-serverless"
  engine                  = "aurora-postgresql"
  engine_version          = "10.7"
  availability_zones      = "${var.availability_zones}"
  db_subnet_group_name    = "${aws_db_subnet_group.postgres_severless.name}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.postgres_severless.name}"
  vpc_security_group_ids  = ["${aws_security_group.postgres_public.id}"]
  database_name           = "${var.database_name}"
  master_username         = "${var.master_username}"
  master_password         = "${random_string.postgres_severless_master_password.result}"
  backup_retention_period = 7
  preferred_backup_window = "04:00-05:00"
  engine_mode             = "serverless"
  skip_final_snapshot     = true
  apply_immediately       = true
  port                    =  "${var.db_port}"

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 16
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  tags = {
    Name = "dbt-postgres-serverless"
  }
}

# to expose postgres outside we need to use an network load balancer
resource "aws_lb" "postgres_severles_lb" {
  name               = "dbt-postgres-serverless"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.public.*.id}"]
  enable_deletion_protection = false

  tags = {
    Name = "dbt-postgres-serverless"
  }
}

resource "aws_lb_target_group" "postgres_severless_target_group" {
  name        = "dbt-postgres-serverless"
  target_type = "ip"
  protocol    = "TCP"
  port        = "${aws_rds_cluster.postgres_severless.port}"
  vpc_id      = "${aws_vpc.vpc.id}"
}

resource "aws_lb_listener" "postgres_severless" {
  load_balancer_arn = "${aws_lb.postgres_severles_lb.id}"
  port              = "${aws_rds_cluster.postgres_severless.port}"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.postgres_severless_target_group.id}"
    type             = "forward"
  }
}

# this lines are depending on the endpoint of postgres, for now a manual step
# do > nslookup endpoint

resource "aws_lb_target_group_attachment" "postgres_serverles_ip_1" {
  target_group_arn = "${aws_lb_target_group.postgres_severless_target_group.arn}"
  target_id        = "10.0.2.95"
}

resource "aws_lb_target_group_attachment" "postgres_serverles_ip_2" {
  target_group_arn = "${aws_lb_target_group.postgres_severless_target_group.arn}"
  target_id        = "10.0.1.232"
}

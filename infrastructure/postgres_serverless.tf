//resource "random_string" "postgres_severless_master_password" {
//  length = 32
//  upper = true
//  number = true
//  special = false
//}
//
//resource "aws_db_subnet_group" "postgres_severless" {
//  name        = "postgres-serverless"
//  description = "Subnet group for postgres serverless"
//  subnet_ids  = ["${aws_subnet.public.*.id}"]
//
//  tags {
//    Name        = "postgres-serverless-subnet-group"
//  }
//}
//
//resource "aws_rds_cluster_parameter_group" "postgres_severless" {
//  name   = "postgres-serverless-pg"
//  family = "aurora-postgresql10"
//  description = "Aurora Postgres Serverless parameter group"
//}
//
//resource "aws_rds_cluster" "postgres_severless" {
//  cluster_identifier      = "dbt-postgres-serverless"
//  engine                  = "aurora-postgresql"
//  engine_version          = "10.7"
//  availability_zones      = "${var.availability_zones}"
//  db_subnet_group_name    = "${aws_db_subnet_group.postgres_severless.name}"
//  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.postgres_severless.name}"
//  vpc_security_group_ids  = ["${aws_security_group.postgres_public.id}"]
//  database_name           = "dbt"
//  master_username         = "root"
//  master_password         = "${random_string.postgres_severless_master_password.result}"
//  backup_retention_period = 7
//  preferred_backup_window = "04:00-05:00"
//  engine_mode             = "serverless"
//  skip_final_snapshot     = true
//  apply_immediately       = true
//
//  scaling_configuration {
//    auto_pause               = true
//    max_capacity             = 64
//    min_capacity             = 2
//    seconds_until_auto_pause = 300
//    timeout_action           = "ForceApplyCapacityChange"
//  }
//
//  tags = {
//    Name = "dbt-postgres-serverless"
//  }
//}

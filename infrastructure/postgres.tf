resource "random_string" "postgres_cluster_master_password" {
  length = 32
  upper = true
  number = true
  special = false
}

resource "aws_db_subnet_group" "postgres_cluster" {
  name        = "postgres-cluster"
  description = "Subnet group for Aurora Postgres cluster"
  subnet_ids  = ["${aws_subnet.public.*.id}"]

  tags {
    Name        = "postgres-cluster-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "postgres_cluster" {
  name   = "postgres-serverless-pg"
  family = "aurora-postgresql10"
  description = "Aurora Postgres Cluster parameter group"
}

resource "aws_rds_cluster" "postgres_cluster" {
  cluster_identifier      = "dbt-postgres-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "10.7"
  availability_zones      = "${var.availability_zones}"
  db_subnet_group_name    = "${aws_db_subnet_group.postgres_cluster.name}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.postgres_cluster.name}"
  vpc_security_group_ids  = ["${aws_security_group.postgres_public.id}"]
  database_name           = "dbt"
  master_username         = "root"
  master_password         = "${random_string.postgres_cluster_master_password.result}"
  backup_retention_period = 7
  preferred_backup_window = "04:00-05:00"

  skip_final_snapshot     = true
  apply_immediately       = true


  tags = {
    Name = "dbt-postgres-cluster"
  }
}

resource "aws_rds_cluster_instance" "postgres_cluster_instance" {
  count                   = 1
  identifier              = "dbt-postgres-cluster-instance-${count.index}"
  cluster_identifier      = "${aws_rds_cluster.postgres_cluster.id}"
  instance_class          = "db.t3.medium" # note that is the only instance available from t3 generation
  publicly_accessible     = true
  engine                  = "aurora-postgresql"
  engine_version          = "10.7"
}

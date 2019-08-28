resource "random_string" "master_postgres_password" {
  length = 32
  upper = true
  number = true
  special = false
}

resource "aws_security_group" "postgres_public" {
  name = "${var.project}-postgres-public-sg"
  description = "Allow all inbound for Postgres"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", "${var.vpc_cidr_block}" ]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-postgres-public-sg"
  }
}

resource "aws_db_subnet_group" "subnet_group" {
  name        = "${var.project}"
  description = "Subnet grup for ${var.project} "
  subnet_ids  = ["${aws_subnet.public.*.id}"]

  tags {
    Name        = "${var.project}-subnet-group"
  }
}


resource "aws_rds_cluster_parameter_group" "cluster_parameter_group" {
  name   = "${var.project}-pg"
  family = "aurora-postgresql10"
  description = "Aurora Postgres parameter group"
}

resource "aws_rds_cluster" "postgres" {

  cluster_identifier      = "${var.project}"
  engine                  = "aurora-postgresql"
  engine_version          = "10.7"
  availability_zones      = "${var.availability_zones}"
  db_subnet_group_name    = "${aws_db_subnet_group.subnet_group.name}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.cluster_parameter_group.name}"
  vpc_security_group_ids  = ["${aws_security_group.postgres_public.id}"]
  database_name           = "dbt"
  master_username         = "root"
  master_password         = "${random_string.master_postgres_password.result}"
  backup_retention_period = 7
  preferred_backup_window = "04:00-05:00"
  engine_mode             = "serverless"
  skip_final_snapshot     = true
  apply_immediately       = true

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 64
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}

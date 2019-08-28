output "postgres_master_password" {
  value = "${random_string.master_postgres_password.result}"
}

output "postgres_master_user" {
  value = "${aws_rds_cluster.postgres.master_username}"
}

output "postgres_endpoint" {
  value = "${aws_rds_cluster.postgres.endpoint}"
}

output "postgres_port" {
  value = "${aws_rds_cluster.postgres.port}"
}

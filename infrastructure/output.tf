//output "postgres_serverless_master_password" {
//  value = "${random_string.postgres_severless_master_password.result}"
//}
//
//output "postgres_serverless_master_user" {
//  value = "${aws_rds_cluster.postgres_severless.master_username}"
//}
//
//output "ppostgres_serverless_endpoint" {
//  value = "${aws_rds_cluster.postgres_severless.endpoint}"
//}


output "postgres_cluster_master_password" {
  value = "${random_string.postgres_cluster_master_password.result}"
}

output "postgres_cluster_master_user" {
  value = "${aws_rds_cluster.postgres_cluster.master_username}"
}

output "ppostgres_cluster_endpoint" {
  value = "${aws_rds_cluster.postgres_cluster.endpoint}"
}

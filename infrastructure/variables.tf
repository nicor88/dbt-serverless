variable "aws_region" {
   default = "eu-west-1"
}

variable "availability_zones" {
   type    = "list"
   default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "project" {
  default = "dbt-serverless"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = "list"
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "db_port" {
  default = "5432"
}

variable "master_username" {
  default = "root"
}

variable "database_name" {
  default = "dbt"
}

variable "dbt_default_schema" {
  default = "dwh"
}

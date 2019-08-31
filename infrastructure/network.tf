resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"

  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = "${
    map(
     "Project", "${var.project}",
     "Name", "${var.project}-vpc",
    )
  }"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${
    map(
     "Project", "${var.project}",
     "Name", "${var.project}-igw"
    )
  }"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = "${
    map(
     "Project", "${var.project}",
     "Name", "${var.project}-public-route",
    )
  }"
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(var.public_subnets, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  count             = "${length(var.public_subnets)}"

  tags = "${
    map(
     "Project", "${var.project}",
     "Name", "${var.project}-public-${element(var.availability_zones, count.index)}",
    )
  }"

  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_security_group" "postgres_public" {
  name = "${var.project}-postgres-public-sg"
  description = "Allow all inbound for Postgres"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group" "ecs_task" {
    name = "${var.project}-ecs-task-sg"
    description = "Security group for ECS tasks"
    vpc_id = "${aws_vpc.vpc.id}"

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project}-ecs-task-sg"
    }
}

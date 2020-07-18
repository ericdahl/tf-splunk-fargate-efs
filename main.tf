provider "aws" {
  region = "us-east-1"
}


module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = var.admin_cidr
}

resource "aws_ecs_cluster" "cluster" {
  name = "tf-splunk-fargate-ecs"
}

data "template_file" "splunk" {
  template = file("templates/splunk.json")
}

resource "aws_ecs_task_definition" "splunk" {
  container_definitions = data.template_file.splunk.rendered
  family                = "splunk"

  requires_compatibilities = [
    "FARGATE",
  ]

  network_mode = "awsvpc"
  cpu          = 4096
  memory       = 10240
}

resource "aws_security_group" "splunk" {
  name   = "splunk"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "splunk_ingress_80" {
  security_group_id = aws_security_group.splunk.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  cidr_blocks = [var.admin_cidr]
}

resource "aws_security_group_rule" "splunk_ingress_8000" {
  security_group_id = aws_security_group.splunk.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 8000
  to_port   = 8000

  cidr_blocks = [var.admin_cidr]
}

resource "aws_ecs_service" "splunk" {

  name            = "splunk"
  cluster         = aws_ecs_cluster.cluster.name
  task_definition = aws_ecs_task_definition.splunk.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.splunk.id,
      module.vpc.sg_allow_egress,
      module.vpc.sg_allow_vpc,
    ]

    subnets = [module.vpc.subnet_public1]
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = 0

}

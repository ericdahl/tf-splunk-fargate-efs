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

  vars = {
    efs_file_system_id = aws_efs_file_system.splunk.id
  }
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

  execution_role_arn = aws_iam_role.splunk_execution_role.arn

  volume {
    name = "opt-splunk"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.splunk.id
    }
  }
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

  platform_version = "1.4.0"

  network_configuration {
    security_groups = [
      aws_security_group.splunk.id,
      module.vpc.sg_allow_egress,
      module.vpc.sg_allow_vpc,
    ]

    subnets          = [module.vpc.subnet_public1]
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = 0

}

resource "aws_security_group" "splunk_efs" {
  name   = "splunk-efs"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "splunk_efs_ingress_2049_splunk" {
  security_group_id        = aws_security_group.splunk_efs.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.splunk.id
  description              = "Allows Splunk SG to connect to EFS"
}

resource "aws_efs_file_system" "splunk" {

  tags = {
    Name = "tf_splunk_fargate_efs"
  }
}

resource "aws_efs_mount_target" "splunk" {
  file_system_id = aws_efs_file_system.splunk.id
  subnet_id      = module.vpc.subnet_private1

  security_groups = [
    aws_security_group.splunk_efs.id,
  ]
}



resource "aws_iam_role" "splunk_execution_role" {

  name = "splunk-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "splunk_execution_role" {
  name = "splunk-execution-role"

  policy =<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}

EOF

}

resource "aws_iam_role_policy_attachment" "splunk_iam_execution" {
  policy_arn = aws_iam_policy.splunk_execution_role.arn
  role = aws_iam_role.splunk_execution_role.name
}

data "aws_ssm_parameter" "ecs_optimized" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_key_pair" "ecd" {
  public_key = var.public_key
}

resource "aws_instance" "default" {
  subnet_id     = module.vpc.subnet_public1
  ami           = data.aws_ssm_parameter.ecs_optimized.value
  instance_type = "t3.medium"

  vpc_security_group_ids = [
    module.vpc.sg_allow_vpc,
    module.vpc.sg_allow_22,
    module.vpc.sg_allow_egress
  ]

  key_name = aws_key_pair.ecd.key_name
}

output "efs" {
  value = aws_efs_file_system.splunk.id
}

output "default" {
  value = aws_instance.default.public_ip
}

resource "aws_cloudwatch_log_group" "splunk" {
  name = "tf_splunk_fargate_efs"
}

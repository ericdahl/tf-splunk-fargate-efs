resource "aws_ecs_task_definition" "splunk" {
  family = "splunk"

  network_mode = "awsvpc"
  cpu          = 4096
  memory       = 10240

  execution_role_arn = aws_iam_role.splunk_execution_role.arn

  volume {
    name = "opt-splunk"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.splunk.id
    }
  }

  container_definitions = jsonencode([
    {
      name : "splunk",
      image : "ericdahl/splunk-efs:d71292e",
      portMappings : [
        {
          containerPort : 8000,
          hostPort : 8000,
          protocol : "tcp"
        },
        {
          containerPort : 8088,
          hostPort : 8088,
          protocol : "tcp"
        }
      ],
      environment : [
        {
          name : "SPLUNK_START_ARGS",
          value : "--accept-license"
        },
        {
          name : "SPLUNK_PASSWORD",
          value : "password"
        }
      ],
      mountpoints : [
        {
          sourceVolume : "opt-splunk",
          containerPath : "/opt/splunk/var"
        }
      ],
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : "tf_splunk_fargate_efs",
          awslogs-region : "us-east-1",
          awslogs-stream-prefix : "splunk"
        }
      }
    }

  ])
}


resource "aws_security_group" "splunk" {
  name   = "splunk"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "splunk_ingress_8000" {
  security_group_id = aws_security_group.splunk.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 8000
  to_port   = 8000

  description = "Access to Web Console from Admin CIDRs"

  cidr_blocks = [var.admin_cidr]
}

resource "aws_security_group_rule" "splunk_ingress_8000_hec" {
  security_group_id = aws_security_group.splunk.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 8088
  to_port   = 8088

  description = "Access to HEC from Admin CIDRs"

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

  load_balancer {
    container_name = "splunk"
    container_port = 8088

    target_group_arn = aws_lb_target_group.splunk_alb_hec.arn
  }

  load_balancer {
    container_name = "splunk"
    container_port = 8000

    target_group_arn = aws_lb_target_group.splunk_alb_console.arn
  }


  deployment_minimum_healthy_percent = 0
  health_check_grace_period_seconds  = 18000


  # Service will fail to be created if the ALB isn't there yet
  depends_on = [aws_lb.splunk_alb]
}

resource "aws_cloudwatch_log_group" "splunk" {
  name = "tf_splunk_fargate_efs"

  retention_in_days = 7
}
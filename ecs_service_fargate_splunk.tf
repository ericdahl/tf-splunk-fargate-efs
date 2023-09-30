resource "aws_ecs_task_definition" "splunk" {
  family = "splunk"

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



resource "aws_acm_certificate" "splunk" {
  domain_name       = aws_route53_record.splunk_alb.fqdn
  validation_method = "DNS"

  tags = {
    Name = aws_route53_record.splunk_alb.fqdn
  }
}

resource "aws_acm_certificate_validation" "splunk" {
  certificate_arn = aws_acm_certificate.splunk.arn

  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.splunk.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}



resource "aws_route53_record" "splunk_alb" {
  zone_id = var.route53_zone_id
  name    = "splunk"
  type    = "CNAME"

  ttl = 15

  records = [
    aws_lb.splunk_alb.dns_name
  ]
}

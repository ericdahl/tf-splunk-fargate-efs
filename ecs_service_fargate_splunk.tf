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
      file_system_id = aws_efs_file_system.splunk.id
    }
  }
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
  health_check_grace_period_seconds = 180


  # Service will fail to be created if the ALB isn't there yet
  depends_on = [aws_lb.splunk_alb]
}

resource "aws_cloudwatch_log_group" "splunk" {
  name = "tf_splunk_fargate_efs"
}

resource "aws_security_group" "splunk_alb" {
  vpc_id = module.vpc.vpc_id

  name = "splunk-alb"
}

resource "aws_security_group_rule" "splunk_alb_ingress_443_admin" {

  security_group_id = aws_security_group.splunk_alb.id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = [var.admin_cidr]
}

resource "aws_security_group_rule" "splunk_alb_ingress_8088_admin" {

  security_group_id = aws_security_group.splunk_alb.id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 8088
  to_port     = 8088
  cidr_blocks = [var.admin_cidr]
}

resource "aws_security_group_rule" "splunk_alb_ingress_8088_all" { # TODO: remove; in place for Kinesis

  security_group_id = aws_security_group.splunk_alb.id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 8088
  to_port     = 8088
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "splunk_alb_egress_all" {
  security_group_id = aws_security_group.splunk_alb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "splunk_alb_ingress_8088_vpc" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8088
  to_port           = 8088
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.splunk_alb.id
}

resource "aws_lb" "splunk_alb" {
  name = "splunk-alb"

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.splunk_alb.id
  ]

  subnets = [
    module.vpc.subnet_public1,
    module.vpc.subnet_public2,
    module.vpc.subnet_public3
  ]
}

resource "aws_acm_certificate" "splunk" {
  domain_name = aws_route53_record.splunk_alb.fqdn
  validation_method = "DNS"

  tags = {
    Name = aws_route53_record.splunk_alb.fqdn
  }
}

resource "aws_route53_record" "acm_validation" {
  name =  aws_acm_certificate.splunk.domain_validation_options[0].resource_record_name
  type = aws_acm_certificate.splunk.domain_validation_options[0].resource_record_type
  zone_id = var.route53_zone_id

  ttl = 15

  records = [
    aws_acm_certificate.splunk.domain_validation_options[0].resource_record_value
  ]
}

resource "aws_lb_listener" "splunk_console" {
  load_balancer_arn = aws_lb.splunk_alb.arn
  port = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.splunk_alb_console.arn
  }

  certificate_arn = aws_acm_certificate.splunk.arn

  depends_on = [
  aws_route53_record.acm_validation
  ]
}

resource "aws_lb_listener" "splunk_hec" {
  load_balancer_arn = aws_lb.splunk_alb.arn
  port = 8088
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.splunk_alb_hec.arn
  }

  certificate_arn = aws_acm_certificate.splunk.arn

  depends_on = [
    aws_route53_record.acm_validation
  ]
}

resource "aws_lb_target_group" "splunk_alb_hec" {
  vpc_id = module.vpc.vpc_id
  name        = "splunk-tg-hec"
  port        = 8088
  protocol    = "HTTPS" # TODO: HTTPS?
  target_type = "ip"

  deregistration_delay = 3

  health_check {
    protocol = "HTTPS"
    path = "/services/collector/health"
  }

}

resource "aws_lb_target_group" "splunk_alb_console" {
  vpc_id = module.vpc.vpc_id
  name        = "splunk-tg-console"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"

  deregistration_delay = 3


  health_check {
    matcher = "200-399"
  }
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

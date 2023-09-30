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

resource "aws_lb_listener" "splunk_console_http" {
  load_balancer_arn = aws_lb.splunk_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.splunk_alb_console.arn
  }
}

resource "aws_lb_listener" "splunk_hec" {
  load_balancer_arn = aws_lb.splunk_alb.arn
  port              = 8088
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.splunk_alb_hec.arn
  }
}

resource "aws_lb_target_group" "splunk_alb_hec" {
  vpc_id      = module.vpc.vpc_id
  name        = "splunk-tg-hec"
  port        = 8088
  protocol    = "HTTP"
  target_type = "ip"

  deregistration_delay = 3

  health_check {
    protocol          = "HTTP"
    path              = "/services/collector/health"
    healthy_threshold = 2
    interval          = 5
    timeout           = 2
  }

}

resource "aws_lb_target_group" "splunk_alb_console" {
  vpc_id      = module.vpc.vpc_id
  name        = "splunk-tg-console"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"

  deregistration_delay = 3


  health_check {
    matcher = "200-399"

    healthy_threshold = 2
    interval          = 5
    timeout           = 2
  }
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

resource "aws_security_group_rule" "splunk_alb_ingress_80_admin" {

  security_group_id = aws_security_group.splunk_alb.id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
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

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  filter {
    name = "prefix-list-name"
    values = ["com.amazonaws.global.cloudfront.origin-facing"]
  }
}

resource "aws_security_group_rule" "splunk_alb_ingress_80_cloudfront" {
  security_group_id = aws_security_group.splunk_alb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80

  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id]
}


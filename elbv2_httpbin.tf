
resource "aws_lb" "httpbin" {
  name               = "httpbin-alb"
  load_balancer_type = "application"

  subnets = [
    module.vpc.subnet_public1,
    module.vpc.subnet_public2,
    module.vpc.subnet_public3,
  ]

  security_groups = [
    module.vpc.sg_allow_egress,
    module.vpc.sg_allow_80,
  ]
}

resource "aws_lb_listener" "httpbin" {
  default_action {
    target_group_arn = aws_lb_target_group.httpbin.arn
    type             = "forward"
  }

  load_balancer_arn = aws_lb.httpbin.arn
  port              = 80
}

resource "aws_lb_target_group" "httpbin" {
  name                 = "httpbin-fargate-firehose"
  vpc_id               = module.vpc.vpc_id
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    interval            = 5
    timeout             = 2
  }
}
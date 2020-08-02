resource "aws_ecs_task_definition" "httpbin" {
  container_definitions = templatefile("templates/httpbin-fargate-firehose.json", {})
  family                = "httpbin-fargate"

  requires_compatibilities = [
    "FARGATE",
  ]

  execution_role_arn = aws_iam_role.httpbin_execution_role.arn

  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512

  task_role_arn = aws_iam_role.task_httpbin.arn
}

resource "aws_iam_role" "task_httpbin" {
  name = "task-httpbin-fargate_firehose"

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

resource "aws_iam_policy" "task_httpbin" {
  name = "task_httpbin"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "firehose:PutRecordBatch"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "task_httpbin" {
  role       = aws_iam_role.task_httpbin.name
  policy_arn = aws_iam_policy.task_httpbin.arn
}

resource "aws_ecs_service" "httpbin" {
  name             = "httpbin"
  cluster          = aws_ecs_cluster.cluster.name
  task_definition  = aws_ecs_task_definition.httpbin.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"


  network_configuration {
    security_groups = [
      module.vpc.sg_allow_8080,
      module.vpc.sg_allow_egress,
      module.vpc.sg_allow_vpc,
    ]

    subnets = [
      module.vpc.subnet_private1,
    ]
  }

  depends_on = [aws_lb.httpbin]

  load_balancer {
    target_group_arn = aws_lb_target_group.httpbin.arn
    container_name   = "httpbin"
    container_port   = 8080
  }
}

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

resource "aws_cloudwatch_log_group" "httpbin" {
  name = "/ecs/httpbin-fargate-firelens-firehose"

  retention_in_days = 7
}

resource "aws_kinesis_firehose_delivery_stream" "httpbin" {
  name = "httpbin-fargate-firelens-app"

  destination = "splunk"

  s3_configuration {
    role_arn           = aws_iam_role.httpbin.arn
    bucket_arn         = aws_s3_bucket.httpbin.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  splunk_configuration {
    hec_endpoint = "https://splunk.ecd-dev.net:8088"      # FIXME
    hec_token    = "bb3714bf-b59c-4971-94b7-30c9244c803a" # FIXME : SSM Parameter?

    retry_duration = 30
  }

}

resource "aws_cloudwatch_log_group" "httpbin_firehose" {
  name = "/aws/kinesisfirehose/httpbin-fargate-firelens-app"

  retention_in_days = 7
}

resource "aws_s3_bucket" "httpbin" {
  bucket = "tf-firehose-httpbin-fargate"
  acl    = "private"
}

resource "aws_iam_role" "httpbin" {
  name = "httpbin-fargate-firehose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy" "httpbin" {
  name = "httpbin"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [

  {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.httpbin.arn}",
                "${aws_s3_bucket.httpbin.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.httpbin.arn}"
        },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }

  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "httpbin" {
  role       = aws_iam_role.httpbin.name
  policy_arn = aws_iam_policy.httpbin.arn
}

resource "aws_route53_record" "httpbin" {
  zone_id = var.route53_zone_id
  name    = "httpbin"
  type    = "CNAME"

  ttl = 15

  records = [
    aws_lb.httpbin.dns_name
  ]
}

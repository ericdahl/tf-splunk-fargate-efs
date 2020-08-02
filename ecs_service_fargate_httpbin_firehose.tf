

//data "template_file" "httpbin_fargate_firehose" {
//  template = file("templates/httpbin-fargate-firehose.json")
//}

resource "aws_ecs_task_definition" "httpbin_fargate_firehose" {
  container_definitions = templatefile("templates/httpbin-fargate-firehose.json", {})
//  container_definitions = data.template_file.httpbin_fargate_firehose.rendered
  family                = "httpbin-fargate"

  requires_compatibilities = [
    "FARGATE",
  ]

  execution_role_arn = aws_iam_role.httpbin_execution_role.arn

  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512

  task_role_arn = aws_iam_role.task_httpbin_fargate_firehose.arn
}

resource "aws_iam_role" "task_httpbin_fargate_firehose" {
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

resource "aws_iam_policy" "task_httpbin_fargate_firehose" {
  name = "task_httpbin_fargate_firehose"

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

resource "aws_iam_role_policy_attachment" "task_httpbin_fargate_firehose" {
  role       = aws_iam_role.task_httpbin_fargate_firehose.name
  policy_arn = aws_iam_policy.task_httpbin_fargate_firehose.arn
}

resource "aws_ecs_service" "httpbin_fargate_firehose" {
  name            = "httpbin-fargate-firehose"
  cluster         = aws_ecs_cluster.cluster.name
  task_definition = aws_ecs_task_definition.httpbin_fargate_firehose.arn
  desired_count   = 1
  launch_type     = "FARGATE"

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

  depends_on = [aws_alb.httpbin_fargate_firehose]

  load_balancer {
    target_group_arn = aws_alb_target_group.httpbin_fargate_firehose.arn
    container_name   = "httpbin"
    container_port   = 8080
  }
}

resource "aws_alb" "httpbin_fargate_firehose" {
  name = "httpbin-fargate-firehose"

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

resource "aws_alb_listener" "httpbin_fargate_firehose" {
  default_action {
    target_group_arn = aws_alb_target_group.httpbin_fargate_firehose.arn
    type             = "forward"
  }

  load_balancer_arn = aws_alb.httpbin_fargate_firehose.arn
  port              = 80
}

resource "aws_alb_target_group" "httpbin_fargate_firehose" {
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

resource "aws_cloudwatch_log_group" "httpbin_fargate_firehose" {
  name = "/ecs/httpbin-fargate-firelens-firehose"

  retention_in_days = 7
}

resource "aws_kinesis_firehose_delivery_stream" "httpbin_fargate_firehose" {
  name = "httpbin-fargate-firelens-app"

  destination = "splunk"

  s3_configuration {
    role_arn           = aws_iam_role.httpbin_fargate_firehose.arn
    bucket_arn         = aws_s3_bucket.httpbin_fargate_firehose.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  splunk_configuration {
    hec_endpoint = "https://splunk.ecd-dev.net:8088" # FIXME
    hec_token = "bb3714bf-b59c-4971-94b7-30c9244c803a" # FIXME : SSM Parameter?

    retry_duration = 30
  }

}

resource "aws_s3_bucket" "httpbin_fargate_firehose" {
  bucket = "tf-firehose-httpbin-fargate"
  acl    = "private"
}

resource "aws_iam_role" "httpbin_fargate_firehose" {
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

resource "aws_iam_policy" "httpbin_fargate_firehose" {
  name = "httpbin_fargate_firehose"

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
                "${aws_s3_bucket.httpbin_fargate_firehose.arn}",
                "${aws_s3_bucket.httpbin_fargate_firehose.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.httpbin_fargate_firehose.arn}"
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

resource "aws_iam_role_policy_attachment" "httpbin_fargate_firehose" {
  role       = aws_iam_role.httpbin_fargate_firehose.name
  policy_arn = aws_iam_policy.httpbin_fargate_firehose.arn
}

resource "aws_route53_record" "httpbin_fargate_firehose" {
  zone_id = var.route53_zone_id
  name    = "httpbin"
  type    = "CNAME"

  ttl = 15

  records = [
    aws_alb.httpbin_fargate_firehose.dns_name
  ]
}

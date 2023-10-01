resource "aws_ecs_task_definition" "httpbin" {

  family = "httpbin-fargate"

  execution_role_arn = aws_iam_role.httpbin_execution_role.arn

  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512

  task_role_arn = aws_iam_role.task_httpbin.arn

  container_definitions = jsonencode([

    {
      name : "httpbin",
      image : "ericdahl/httpbin:e249975",
      portMappings : [
        {
          "containerPort" : 8080,
          "hostPort" : 8080,
          "protocol" : "tcp"
        }
      ],
      essential : true,
      logConfiguration : {
        logDriver : "awsfirelens",
        options : {
          Name : "firehose",
          region : "us-east-1",
          delivery_stream : "splunk"
        }
      }
    },
    # this is only here to show multiple container_names in logs
    {
      name : "redis",
      image : "redis",
      essential : true,
      logConfiguration : {
        logDriver : "awsfirelens",
        options : {
          Name : "firehose",
          region : "us-east-1",
          delivery_stream : "splunk"
        }
      }
    },
    {
      name : "firelens",
      image: "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest",
      user : "0",
      essential : true,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : "/ecs/httpbin-fargate-firelens-firehose",
          awslogs-region : "us-east-1",
          awslogs-stream-prefix : "firelens"
        }
      },
      firelensConfiguration : {
        "type" : "fluentbit"
      }
    }
  ])


}


resource "aws_ecs_service" "httpbin" {
  name             = "httpbin"
  cluster          = aws_ecs_cluster.cluster.name
  task_definition  = aws_ecs_task_definition.httpbin.arn
  desired_count    = 3

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

  # bug - https://github.com/hashicorp/terraform-provider-aws/issues/22823
  lifecycle {
    ignore_changes = [capacity_provider_strategy]
  }
}

# Logs from fluent-bit sidecar on httpbin service
resource "aws_cloudwatch_log_group" "httpbin" {
  name              = "/ecs/httpbin-fargate-firelens-firehose"
  retention_in_days = 7
}

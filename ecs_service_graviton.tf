resource "aws_ecs_task_definition" "graviton" {

  family = "graviton-fargate"

  execution_role_arn = aws_iam_role.graviton_execution_role.arn

  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512

  task_role_arn = aws_iam_role.task_graviton.arn

  runtime_platform {
    cpu_architecture = "ARM64"
  }

  container_definitions = jsonencode([

    {
      name : "graviton",
#      image: "gcr.io/kuar-demo/kuard-arm64:blue"
      image : "arm64v8/busybox",
      command:  ["sh", "-c", "while true; do date; sleep 5; done"],
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
      firelensConfiguration : {
        "type" : "fluentbit"
      }
    }
  ])
}


resource "aws_ecs_service" "graviton" {
  name             = "graviton"
  cluster          = aws_ecs_cluster.cluster.name
  task_definition  = aws_ecs_task_definition.graviton.arn
  desired_count    = 1


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

  # bug - https://github.com/hashicorp/terraform-provider-aws/issues/22823
  lifecycle {
    ignore_changes = [capacity_provider_strategy]
  }
}

# Logs from fluent-bit sidecar on graviton service
resource "aws_cloudwatch_log_group" "graviton" {
  name              = "/ecs/graviton-fargate-firelens-firehose"
  retention_in_days = 7
}

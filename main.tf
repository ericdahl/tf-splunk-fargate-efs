provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Name = "tf-splunk-fargate-efs"
    }
  }
}

data "aws_default_tags" "default" {}

module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = var.admin_cidr
}

resource "aws_ecs_cluster" "cluster" {
  name = "tf-splunk-fargate-ecs"


}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

locals {
  name = data.aws_default_tags.default.tags["Name"]
  splunk_hec_token_ack = "11111111-1111-1111-1111-111111111111"


  splunk_alb_hec_endpoint            = "${lower(aws_lb_listener.splunk_hec.protocol)}://${aws_lb.splunk_alb.dns_name}:${aws_lb_listener.splunk_hec.port}"
  splunk_alb_console_endpoint        = "${lower(aws_lb_listener.splunk_console_http.protocol)}://${aws_lb.splunk_alb.dns_name}:${aws_lb_listener.splunk_console_http.port}"
  splunk_cloudfront_hec_endpoint     = "https://${aws_cloudfront_distribution.splunk.domain_name}/services/collector/event"
  splunk_cloudfront_console_endpoint = "https://${aws_cloudfront_distribution.splunk.domain_name}"

  httpbin_alb_endpoint = "${lower(aws_lb_listener.httpbin.protocol)}://${aws_lb.httpbin.dns_name}"
}





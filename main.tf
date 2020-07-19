provider "aws" {
  region = "us-east-1"
}


module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = var.admin_cidr
}

resource "aws_ecs_cluster" "cluster" {
  name = "tf-splunk-fargate-ecs"
}






data "aws_ssm_parameter" "ecs_optimized" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_key_pair" "ecd" {
  public_key = var.public_key
}

resource "aws_instance" "default" {
  subnet_id     = module.vpc.subnet_public1
  ami           = data.aws_ssm_parameter.ecs_optimized.value
  instance_type = "t3.medium"

  vpc_security_group_ids = [
    module.vpc.sg_allow_vpc,
    module.vpc.sg_allow_22,
    module.vpc.sg_allow_egress
  ]

  key_name = aws_key_pair.ecd.key_name
}




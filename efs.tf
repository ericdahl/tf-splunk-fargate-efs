resource "aws_efs_file_system" "splunk" {

  tags = {
    Name = "tf_splunk_fargate_efs"
  }
}

resource "aws_efs_mount_target" "splunk" {
  file_system_id = aws_efs_file_system.splunk.id
  subnet_id      = module.vpc.subnet_private1

  security_groups = [
    aws_security_group.splunk_efs.id,
  ]
}

resource "aws_security_group" "splunk_efs" {
  name   = "splunk-efs"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "splunk_efs_ingress_2049_splunk" {
  security_group_id        = aws_security_group.splunk_efs.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.splunk.id
  description              = "Allows Splunk SG to connect to EFS"
}

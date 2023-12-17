
data "aws_ssm_parameter" "ecs_optimized" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_key_pair" "default" {
  public_key = var.public_key
}



# used just for debugging from within the VPC; not necessary
resource "aws_instance" "jumphost" {
  subnet_id     = module.vpc.subnet_public1
  ami           = data.aws_ssm_parameter.ecs_optimized.value
  instance_type = "t3.medium"

  vpc_security_group_ids = [
    module.vpc.sg_allow_vpc,
    module.vpc.sg_allow_22,
    module.vpc.sg_allow_egress,
    aws_security_group.splunk.id #  hack to allow it to mount the EFS volume
  ]

  key_name = aws_key_pair.default.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2.name
}


data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "jumphost" {
  name        = "${local.name}-jumphost"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "jumphost_ssm" {
  role      = aws_iam_role.jumphost.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${aws_iam_role.jumphost.name}-instance-profile"
  role = aws_iam_role.jumphost.name
}

resource "aws_iam_role_policy_attachment" "ec2_ecs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.jumphost.name
}
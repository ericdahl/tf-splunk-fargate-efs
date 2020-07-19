resource "aws_iam_role" "splunk_execution_role" {

  name = "splunk-execution-role"

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

resource "aws_iam_policy" "splunk_execution_role" {
  name = "splunk-execution-role"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}

EOF

}

resource "aws_iam_role_policy_attachment" "splunk_iam_execution" {
  policy_arn = aws_iam_policy.splunk_execution_role.arn
  role       = aws_iam_role.splunk_execution_role.name
}

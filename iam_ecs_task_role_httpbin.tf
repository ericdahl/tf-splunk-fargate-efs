
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

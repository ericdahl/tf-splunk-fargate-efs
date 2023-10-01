resource "aws_iam_role" "task_splunk" {
  name = "task-splunk-fargate_firehose"

  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_tasks.json
}

data "aws_iam_policy_document" "task_role_splunk" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:PutRecordBatch"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "task_splunk" {
  name = "task_splunk"

  policy = data.aws_iam_policy_document.task_role_splunk.json
}

resource "aws_iam_role_policy_attachment" "task_splunk" {
  role       = aws_iam_role.task_splunk.name
  policy_arn = aws_iam_policy.task_splunk.arn
}

resource "aws_iam_role_policy_attachment" "splunk_task_execution" {
  role       = aws_iam_role.task_splunk.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
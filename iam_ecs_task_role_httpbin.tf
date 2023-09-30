
resource "aws_iam_role" "task_httpbin" {
  name = "task-httpbin-fargate_firehose"

  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_tasks.json
}

data "aws_iam_policy_document" "task_role_httpbin" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:PutRecordBatch"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "task_httpbin" {
  name = "task_httpbin"

  policy = data.aws_iam_policy_document.task_role_httpbin.json
}

resource "aws_iam_role_policy_attachment" "task_httpbin" {
  role       = aws_iam_role.task_httpbin.name
  policy_arn = aws_iam_policy.task_httpbin.arn
}

resource "aws_iam_role" "task_graviton" {
  name = "task-graviton-fargate_firehose"

  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_tasks.json
}

data "aws_iam_policy_document" "task_role_graviton" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:PutRecordBatch"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "task_graviton" {
  name = "task_graviton"

  policy = data.aws_iam_policy_document.task_role_graviton.json
}

resource "aws_iam_role_policy_attachment" "task_graviton" {
  role       = aws_iam_role.task_graviton.name
  policy_arn = aws_iam_policy.task_graviton.arn
}

resource "aws_iam_role_policy_attachment" "graviton_task_execution" {
  role       = aws_iam_role.task_graviton.name
  policy_arn = aws_iam_policy.ecs_task_exec_command.arn
}
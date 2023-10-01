
data "aws_iam_policy_document" "ecs_task_exec_command" {

  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ecs_task_exec_command" {
  name = "ecs-task-execute-command"
  policy = data.aws_iam_policy_document.ecs_task_exec_command.json
}
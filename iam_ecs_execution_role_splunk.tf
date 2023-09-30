resource "aws_iam_role" "splunk_execution_role" {

  name               = "splunk-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_tasks.json
}

data "aws_iam_policy_document" "execution_role_splunk" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "splunk_execution_role" {
  name = "splunk-execution-role"

  policy = data.aws_iam_policy_document.execution_role_splunk.json
}

resource "aws_iam_role_policy_attachment" "splunk_iam_execution" {
  policy_arn = aws_iam_policy.splunk_execution_role.arn
  role       = aws_iam_role.splunk_execution_role.name
}

resource "aws_iam_role" "graviton_execution_role" {
  name               = "graviton-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_tasks.json
}

data "aws_iam_policy_document" "execution_role_graviton" {
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


resource "aws_iam_policy" "graviton_execution_role" {
  name   = "graviton-execution-role"
  policy = data.aws_iam_policy_document.execution_role_graviton.json
}

resource "aws_iam_role_policy_attachment" "graviton_iam_execution" {
  policy_arn = aws_iam_policy.graviton_execution_role.arn
  role       = aws_iam_role.graviton_execution_role.name
}

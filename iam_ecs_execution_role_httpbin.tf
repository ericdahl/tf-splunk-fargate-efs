data "aws_iam_policy_document" "assume_role_ecs_tasks" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "httpbin_execution_role" {
  name               = "httpbin-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_tasks.json
}

data "aws_iam_policy_document" "execution_role_httpbin" {
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


resource "aws_iam_policy" "httpbin_execution_role" {
  name   = "httpbin-execution-role"
  policy = data.aws_iam_policy_document.execution_role_httpbin.json
}

resource "aws_iam_role_policy_attachment" "httpbin_iam_execution" {
  policy_arn = aws_iam_policy.httpbin_execution_role.arn
  role       = aws_iam_role.httpbin_execution_role.name
}

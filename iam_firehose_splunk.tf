data "aws_iam_policy_document" "assume_role_firehose" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_splunk" {
  name               = "firehose-stream-splunk"
  assume_role_policy = data.aws_iam_policy_document.assume_role_firehose.json
}

data "aws_iam_policy_document" "firehose_splunk" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.kinesis_stream_splunk_backup.arn,
      "${aws_s3_bucket.kinesis_stream_splunk_backup.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords"
    ]

    resources = [
      aws_kinesis_firehose_delivery_stream.splunk.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}


resource "aws_iam_policy" "firehose_splunk" {
  name   = "firehose-stream-splunk"
  policy = data.aws_iam_policy_document.firehose_splunk.json
}

resource "aws_iam_role_policy_attachment" "httpbin" {
  role       = aws_iam_role.firehose_splunk.name
  policy_arn = aws_iam_policy.firehose_splunk.arn
}

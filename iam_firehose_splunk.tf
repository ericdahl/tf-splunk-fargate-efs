
resource "aws_iam_role" "firehose_splunk" {
  name = "firehose-stream-splunk"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy" "firehose_splunk" {
  name = "firehose-stream-splunk"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [

  {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.httpbin.arn}",
                "${aws_s3_bucket.httpbin.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.splunk.arn}"
        },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }

  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "httpbin" {
  role       = aws_iam_role.firehose_splunk.name
  policy_arn = aws_iam_policy.firehose_splunk.arn
}

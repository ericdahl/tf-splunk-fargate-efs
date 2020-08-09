resource "aws_kinesis_firehose_delivery_stream" "httpbin" {
  name = "httpbin-fargate-firelens-app"

  destination = "splunk"

  s3_configuration {
    role_arn           = aws_iam_role.httpbin.arn
    bucket_arn         = aws_s3_bucket.httpbin.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  splunk_configuration {
    hec_endpoint = "https://splunk.ecd-dev.net:8088"
    hec_token    = "11111111-1111-1111-1111-111111111111"

    retry_duration = 30
  }

}

resource "aws_cloudwatch_log_group" "httpbin" {
  name = "/ecs/httpbin-fargate-firelens-firehose"

  retention_in_days = 7
}


resource "aws_iam_role" "httpbin" {
  name = "httpbin-fargate-firehose"

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

resource "aws_iam_policy" "httpbin" {
  name = "httpbin"

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
            "Resource": "${aws_kinesis_firehose_delivery_stream.httpbin.arn}"
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
  role       = aws_iam_role.httpbin.name
  policy_arn = aws_iam_policy.httpbin.arn
}

resource "aws_s3_bucket" "httpbin" {
  bucket = "tf-firehose-httpbin-fargate"
  acl    = "private"
}

resource "aws_cloudwatch_log_group" "httpbin_firehose" {
  name = "/aws/kinesisfirehose/httpbin-fargate-firelens-app"

  retention_in_days = 7
}

resource "aws_kinesis_firehose_delivery_stream" "splunk" {
  name = "splunk"

  destination = "splunk"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_splunk.arn
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

resource "aws_s3_bucket" "httpbin" {
  bucket = "tf-firehose-httpbin-fargate"
  acl    = "private"
}

resource "aws_cloudwatch_log_group" "httpbin_firehose" {
  name = "/aws/kinesisfirehose/httpbin-fargate-firelens-app"

  retention_in_days = 7
}

resource "aws_kinesis_firehose_delivery_stream" "splunk" {
  name        = "splunk"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint = "https://splunk.ecd-dev.net:8088"
    hec_token    = local.splunk_hec_token_ack

    retry_duration = 30

    s3_configuration {
      role_arn           = aws_iam_role.firehose_splunk.arn
      bucket_arn         = aws_s3_bucket.httpbin.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }

  }
}

resource "aws_s3_bucket" "httpbin" {
  bucket        = "tf-firehose-httpbin-fargate"
  acl           = "private"
  force_destroy = true
}

resource "aws_cloudwatch_log_group" "httpbin_firehose" {
  name = "/aws/kinesisfirehose/httpbin-fargate-firelens-app"

  retention_in_days = 7
}

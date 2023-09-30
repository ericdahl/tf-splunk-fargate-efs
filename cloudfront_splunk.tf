resource "aws_cloudfront_distribution" "splunk" {
  enabled = true

  origin {
    domain_name = aws_lb.splunk_alb.dns_name
    origin_id   = "splunk-console"

    custom_origin_config {
      http_port              = aws_lb_listener.splunk_console_http.port
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = aws_lb.splunk_alb.dns_name
    origin_id   = "splunk-hec"

    custom_origin_config {
      http_port              = aws_lb_listener.splunk_hec.port
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "splunk-console"
    viewer_protocol_policy = "allow-all"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

   forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/services/collector/*"
    target_origin_id       = "splunk-hec"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    viewer_protocol_policy = "https-only"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
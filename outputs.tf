output "efs" {
  value = aws_efs_file_system.splunk.id
}

output "jumphost" {
  value = aws_instance.jumphost.public_ip
}

output "splunk" {
  value = {
    alb = {
      console = local.splunk_alb_console_endpoint
      hec = local.splunk_alb_hec_endpoint
    }
    cloudfront = {
      console = local.splunk_cloudfront_console_endpoint
      hec = local.splunk_cloudfront_hec_endpoint
    }
  }
}

#output "httpbin" {
#  value = {
#    alb = {
#      console = local.splunk_alb_console_endpoint
#      hec = local.splunk_alb_hec_endpoint
#    }
#    cloudfront = {
#      console = local.splunk_cloudfront_console_endpoint
#      hec = local.splunk_alb_hec_endpoint
#    }
#  }
#}
output "efs" {
  value = aws_efs_file_system.splunk.id
}

output "default" {
  value = aws_instance.default.public_ip
}

output "efs" {
  value = aws_efs_file_system.splunk.id
}

output "jumphost" {
  value = aws_instance.jumphost.public_ip
}

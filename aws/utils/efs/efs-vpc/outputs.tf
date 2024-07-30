output "efs_id" {
  value = aws_efs_file_system.efs.id
}

output "efs_ap_id" {
  value = aws_efs_access_point.efs_ap.id
}
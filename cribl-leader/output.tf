output "logstream_leader_ip" {
  value = data.aws_instance.leader.public_ip
}

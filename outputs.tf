output "aws_ami_id_list" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "aws_ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}
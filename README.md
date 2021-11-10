```hcl
terraform {

}

provider "aws" {
  region = "eu-central-1"
}

module "apache" {
  source            = ".//terraform-aws-apache-example"
  vpc_cidr_block    = "10.0.0.0/16"
  subnet_cidr_block = "10.0.10.0/24"
  avail_zone        = "eu-central-1a"
  env_prefix        = "dev"
  #keep only necessary IPs
  #my_ip = "178.191.165.151/32"
  my_ip         = "0.0.0.0/0"
  instance_type = "t2.micro"
  public_key = file(~/.ssh/authorized_keys)

}

output "PublicIP" {
  value = module.apache.aws_ec2_public_ip
}
```
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id                  = aws_vpc.myapp-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 10)
  map_public_ip_on_launch = true
  count                   = 3
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}


resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }

}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]

  }
}
resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []

  }
  tags = {
    Name = "${var.env_prefix}-dev-sg"
  }
}
resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+jgGn3ghNT7WdaqQ9ZLdJL2FuijDvg7yfMFT5h6dWMNXKkGY8XAQ0ijLEtJlA8enoNlZbbUYvOHeYYjVZUIBs1w8NKfcUgbMqjyWCfNfPV4DKJ7wD/B0AwElMrfSdf+xQf188iOs6aAMzDtjTQFwJ+VFRYF9xoj9zcZ19lOZmhiNvZsPZAqtYHkaz5mGUEX42EmXP18lAMIRhQzyaCaoVNHJpYIgpBut1NrrNdvnpGQvZV8iPgHUttpAw+DdL6453+3NRXwVCnCtJTTVAbPIVE+HMFj46nuXx4rspaAZBCTWoLFQIFPSFHLmiMFNcch2O+st1brwcWcm/1ZTxmDDa60Hleb3r3aHqCmwdjmmn7xVJhT8L2co44a2j0gxzS/50EYmAvpob4lyGHNLq7auuQopCh8mDu++xKhDRWnZG/8DJEHJBSbUXklK95fapunNRPGds1t6boTOQStYApTHz+1gNFXawmS7DjGyZxdqlYFyo8cDeQT0sN2GM79QuDSE= z003ww7c@md1ywc2c"

}
resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id                   = flatten(aws_subnet.myapp-subnet-1.*.id)[0]
  vpc_security_group_ids      = [aws_default_security_group.default-sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  user_data = file("${abspath(path.module)}/entry-script.sh")

  tags = {
    Name = "${var.env_prefix} - server"

  }
  lifecycle {
    prevent_destroy = false
  }
}
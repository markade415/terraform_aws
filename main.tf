provider "aws" {
    region = var.region
    version = "3.4.0"
}

# create a vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "production"
  }
}

# create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# create a custom route table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}
  # create a subnet

  resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "prod-subnet"
  }
}

#create a subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# create a security group to allow port 22, 80 and 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# create a network interface 

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#Assign an elastic ip to the network interface

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# create Ubuntu server and install/enable apche2

resource "aws_instance" "web-server" {
  ami           =  var.ami
  instance_type = var.instance-type
  availability_zone= "us-west-1a"
  key_name = "keybizz"
  

  network_interface  {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id

  }

  user_data =  <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              systemctl start apache2
              sudo bash -c 'echo your very first webserver > /var/www/html/index.html'
              EOF
  
  tags = {
    Name        = "web-server"
  }
}

#resource "aws_key_pair" "default" {
 #   key_name = "dev-key"
 #   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqCijxhxKB2y8y/n05xP4HKDV+104mczDtHfttEpIiCoj0vAh7d30XiysnY1R7VcfdghsjCGWz5sDYNgbIa+5azCVI0s5X8exOs+YBxYMUGoJrZ2PzUeAsdA1DE0m5n9kL1Hkzsj5GngMVv2M16SljgU4UHHe1CggVGrWSMEC+pYpTjK2FsovkrR9fijKZtIVp4cTQLto5g2iXEml7UV4jOY4stx7H9U/sUwIWzEoh9DpkMFALXIZWA3NyjDhqDX4U41D4EoiaxtgLALuX6m0tq540kjO0RgDhV37jla0U79esh/1sMxrwmsRk33t4QZkjp6IdTjfSlz8ZLmKU5W4OQ== rsa-key-20200831"
#}
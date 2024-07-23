#1 Create a VPC
resource "aws_vpc" "zac-vpc" {
  cidr_block       = "25.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"

  tags = {
    Name = "zac-vpc"
    environment = "devops"
  }
}

#2 Create IGW
resource "aws_internet_gateway" "zac-igw" {
  vpc_id = aws_vpc.zac-vpc.id

  tags = {
    Name = "zac-igw"
    environment = "devops"
  }
}

#3 Create a custom/Public RT
resource "aws_route_table" "zac-prt" {
  vpc_id = aws_vpc.zac-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.zac-igw.id
  }

#Since we are not using ipv6, we comment the next block out
#  route {
#    ipv6_cidr_block        = "::/0"
#    egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
#  }

  tags = {
    Name = "zac-prt"
    environment = "devops"
  }
}

#4 Create a public subnet in eu-west-2a
resource "aws_subnet" "zac-pubsn-2a" {
  vpc_id     = aws_vpc.zac-vpc.id
  availability_zone = "eu-west-2a"
  cidr_block = "25.0.0.0/24"

  tags = {
    Name = "zac-pubsn"
    environment = "devops"
  }
}

#5 Associate the subnet with the RT
resource "aws_route_table_association" "zac-a" {
  subnet_id      = aws_subnet.zac-pubsn-2a.id
  route_table_id = aws_route_table.zac-prt.id
}

#6 Create a security group
resource "aws_security_group" "zac-pubsg" {
  name        = "zac-pubsg"
  description = "Allow access to SSH and RDP from a single IP address and https from anywhere"
  vpc_id      = aws_vpc.zac-vpc.id

  #INBOUND RULES
    #SSH
    ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["192.168.180.23/32"]   #we are using CIDR 32 because the request mentioned only one cidr
    #ipv6_cidr_blocks = ["::/0"]
  }
    #RDP
    ingress {
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["192.168.180.23/32"]   
    #ipv6_cidr_blocks = ["::/0"]
  }

    #HTTPS
    ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   
    #ipv6_cidr_blocks = ["::/0"]
  }

  #OUTBOUND RULES
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  #this specifies all protocols are allowed out
    cidr_blocks      = ["0.0.0.0/0"]   
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "zac-pubsg"
    environment = "devops"
  }
}

#7 Create a network interface with an IP in the subnet that was created in step 4
resource "aws_network_interface" "zac-pubni-2a" {
  subnet_id = aws_subnet.zac-pubsn-2a.id
  private_ips = ["25.0.0.4"] #note that you can't pick the IPs, .1,.2,.3,.255 since these are locked by default
  security_groups = [aws_security_group.zac-pubsg.id]

#  attachment {
#    instance = 
#    device_index = 1
#  }
}

#8 Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "zac-eip1" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.zac-pubni-2a.id
  associate_with_private_ip = "25.0.0.4"

  depends_on = [aws_internet_gateway.zac-igw]
}

#9 Launch an  EC2 instance
resource "aws_instance" "zac-ec2" {
  ami           = "ami-08447c25f2e9dc66c" # eu-west-2, ubuntu 20.04
  instance_type = "t2.micro"
  key_name = "zeeks-kp"

  network_interface {
    network_interface_id = aws_network_interface.zac-pubni-2a.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 12
  }

    tags = {
    Name = "zac-server1"
    environment = "devops"
  }
}
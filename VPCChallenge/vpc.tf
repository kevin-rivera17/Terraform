#Create a VPC
#terraform aws create vpc
resource "aws_vpc" "kev-vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    "Name" = "kev-vpc-tf"
  }
}
#CREATE SECURITY GROUP
resource "aws_security_group" "ServicesSG" {
  name        = "ServiceSG"
  description = "Allowing SSH and ports for the VPN"
  vpc_id      = aws_vpc.kev-vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 943
    to_port          = 943
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 1194
    to_port          = 1194
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TF-SG"
  }
}

#CREATE PRIVATE SUBNETS
resource "aws_subnet" "private1" {
  vpc_id = aws_vpc.kev-vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "1-privates"
  }
}

resource "aws_subnet" "private2" {
  vpc_id = aws_vpc.kev-vpc.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "2-privates"
  }
}
resource "aws_subnet" "private3" {
  vpc_id = aws_vpc.kev-vpc.id
  cidr_block = "10.1.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name" = "3-privates"
  }
}

#CREATING PUBLIC SUBNETS
resource "aws_subnet" "public1" {
  vpc_id = aws_vpc.kev-vpc.id
  cidr_block = "10.1.4.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "1-publics"
  }
}
resource "aws_subnet" "public2" {
  vpc_id = aws_vpc.kev-vpc.id
  cidr_block = "10.1.5.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "2-publics"
  }
}
resource "aws_subnet" "publice3" {
  vpc_id = aws_vpc.kev-vpc.id
  cidr_block = "10.1.6.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "3-publics"
  }
}

#CREATING INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.kev-vpc.id

  tags = {
    "Name" = "kev-internet-gw"
  }
}

#PUBLIC ROUTE TABLE
resource "aws_route_table" "Public" {
  vpc_id = aws_vpc.kev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "Public Route Table"
  }
}

#ASSOCIATE PUBLICS SUBNETS TO PUBLIC ROUTING TABLE
resource "aws_route_table_association" "rt-public-1" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.Public.id
}
resource "aws_route_table_association" "rt-public-2" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.Public.id
}
resource "aws_route_table_association" "rt-public-3" {
  subnet_id = aws_subnet.publice3.id
  route_table_id = aws_route_table.Public.id
}

#CREATIN PRIVATE ROUTE TABLE
resource "aws_route_table" "Private-tb" {
  vpc_id = aws_vpc.kev-vpc.id

  tags = {
    "Name" = "Private Route Table"
  }
}

#ASSOCIATE PRIVATE SUBNETS TO PRIVATE ROUTING TABLE
resource "aws_route_table_association" "rt-private-1" {
  subnet_id = aws_subnet.private1.id
  route_table_id = aws_route_table.Private-tb.id
}
resource "aws_route_table_association" "rt-private-2" {
  subnet_id = aws_subnet.private2.id
  route_table_id = aws_route_table.Private-tb.id
}
resource "aws_route_table_association" "rt-private-3" {
  subnet_id = aws_subnet.private3.id
  route_table_id = aws_route_table.Private-tb.id
}


#CREATING AND LAUNCHING EC2 INSTANCES
#AMAZON LINUX AMI ami-0ab4d1e9cf9a1215a
#VPN - UBUNTU AMI ami-09e67e426f25ce0d7
resource "aws_instance" "instance1" {
  ami = "ami-0ab4d1e9cf9a1215a"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private1.id
  key_name = "kev-tf-key"
  user_data = file("user_data.txt")
  tags = {
    "Name" = "Instance-1"
  }
}

resource "aws_instance" "instance2" {
  ami = "ami-0ab4d1e9cf9a1215a"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private2.id
  key_name = "kev-tf-key"
  user_data = file("user_data.txt")
  tags = {
    "Name" = "Instance-2"
  }
}

resource "aws_instance" "instance3" {
  ami = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.publice3.id
  vpc_security_group_ids = ["${aws_security_group.ServicesSG.id}"]
  key_name = "kev-tf-key"
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              apt update && apt -y install ca-certificates wget net-tools gnupg
              wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add -
              echo "deb http://as-repository.openvpn.net/as/debian focal main">/etc/apt/sources.list.d/openvpn-as-repo.list
              apt update && apt -y install openvpn-as
              echo "17231996Next" | passwd --stdin openvpn
              EOF

  tags = {
    "Name" = "VPN"
  }
}

#CREATE ELB FOR THE EC2

provider "aws" {
  region = "ap-south-2"
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = true # Automatically assigns public IPs to resources inside this subnet

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ssh_sg" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For production, restrict this to your specific public IP
  }

  ingress {
    description = "Http from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For production, restrict this to your specific public IP
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-sg"
  }
}

resource "aws_network_interface" "server_nic" {
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.ssh_sg.id]

  tags = {
    Name = "server-nic"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer_key.key_name

  primary_network_interface {
    network_interface_id = aws_network_interface.server_nic.id
  }

  tags = {
    Name = "EC2-With-Custom-Network"
  }
}

# output "instance_public_ip" {
#   description = "The public IP of the EC2 instance assigned via the ENI"
#   value       = aws_network_interface.server_nic.association.public_ip
# }

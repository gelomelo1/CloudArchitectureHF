provider "aws" {
  region = "us-east-1"
}

# ---------------- VPC ----------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# ---------------- SUBNET ----------------
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# ---------------- IGW ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# ---------------- ROUTE TABLE ----------------
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

# ---------------- AMI ----------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------------- KEY ----------------
resource "aws_key_pair" "key" {
  key_name   = "mykey"
  public_key = file("mykey.pub")
}

# ---------------- SECURITY GROUP WEB ----------------
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- SECURITY GROUP DB ----------------
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- DB INSTANCE ----------------
resource "aws_instance" "db" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name

  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  user_data = file("db-init.sh")
}

# ---------------- WEB INSTANCE ----------------
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name

  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = templatefile("web-init.sh", {
    db_host = aws_instance.db.private_ip
  })
}

# ---------------- ELASTIC IP ----------------
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
}
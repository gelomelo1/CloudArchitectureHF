# Beállítom az AWS providert és a használt régiót
provider "aws" {
  region = "us-east-1"
}

# Létrehozok egy VPC-t saját IP tartománnyal és DNS támogatással
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Terraform VPC"
  }
}

# Létrehozok egy subnetet a VPC-n belül
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Terraform Subnet"
  }
}

# Létrehozok egy internet gateway-t a VPC internet eléréséhez
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Terraform Internet Gateway"
  }
}

# Létrehozok egy route table-t a hálózati útvonalak kezelésére
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Terraform Route Table"
  }
}

# Hozzáadok a route table-hez egy alapértelmezett útvonalat az internet felé
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Összekapcsolom a subnetet a route table-lel
resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

# Lekérem a legfrissebb Amazon Linux 2 AMI-t
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Létrehozok egy SSH kulcspárt a példányokhoz való hozzáféréshez
resource "aws_key_pair" "key" {
  key_name   = "mykey"
  public_key = file("mykey.pub")

  tags = {
    Name = "Terraform Key Pair"
  }
}

# Létrehozok egy security groupot a web szerver számára HTTP, SSH és ICMP eléréssel
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

  tags = {
    Name = "Terraform Web Security Group"
  }
}

# Létrehozok egy security groupot az adatbázis számára, amely csak a web szervertől fogad MySQL kapcsolatot
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

  tags = {
    Name = "Terraform Database Security Group"
  }
}

# Létrehozok egy EC2 példányt adatbázis szerver céljára
resource "aws_instance" "db" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name

  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  user_data = file("db-init.sh")

  tags = {
    Name = "Terraform Database Instance"
  }
}

# Létrehozok egy EC2 példányt web szerver céljára és átadom a DB privát IP-jét
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name

  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = templatefile("web-init.sh", {
    db_host = aws_instance.db.private_ip
  })

  tags = {
    Name = "Terraform Web Instance"
  }
}

# Hozzárendelek egy publikus Elastic IP címet a web szerverhez
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id

  tags = {
    Name = "Terraform Web EIP"
  }
}
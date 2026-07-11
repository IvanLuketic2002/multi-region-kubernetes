provider "aws" {
  alias  = "frankfurt"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "pariz"
  region = "eu-west-3"
}

# --- DINAMIČKI UBUNTU AMI DETEKTORI ---
data "aws_ami" "ubuntu_frankfurt" {
  provider    = aws.frankfurt
  most_recent = true
  owners      = ["099720109477"] # Zvanični Canonical AWS nalog

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "ubuntu_pariz" {
  provider    = aws.pariz
  most_recent = true
  owners      = ["099720109477"] # Zvanični Canonical AWS nalog

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- SECURITY GROUPS ---
resource "aws_security_group" "sg_k8s_frankfurt" {
  provider    = aws.frankfurt
  name        = "k8s-security-group"
  description = "Omogucava SSH, K8s API i NodePort pristup"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_k8s_pariz" {
  provider    = aws.pariz
  name        = "k8s-security-group"
  description = "Omogucava SSH, K8s API i NodePort pristup"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 INSTANCE (Sada koriste dinamički id) ---
resource "aws_instance" "k8s_frankfurt" {
  provider               = aws.frankfurt
  ami                    = data.aws_ami.ubuntu_frankfurt.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg_k8s_frankfurt.id]

  tags = { Name = "K3s-Cluster-Frankfurt" }
}

resource "aws_instance" "k8s_pariz" {
  provider               = aws.pariz
  ami                    = data.aws_ami.ubuntu_pariz.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg_k8s_pariz.id]

  tags = { Name = "K3s-Cluster-Pariz" }
}

# --- OUTPUTS ---
output "frankfurt_cluster_ip" { value = aws_instance.k8s_frankfurt.public_ip }
output "pariz_cluster_ip"    { value = aws_instance.k8s_pariz.public_ip }

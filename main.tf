variable "name" { default = "dynamic-aws-creds-consumer" }
variable "path" { default = "terraform-technical-marketing-demo/terraform-aws-dynmaic-secrets-producer" }
variable "ttl"  { default = "1" }

terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "terraform-technical-marketing-demo"
    }
  }

data "terraform_remote_state" "producer" {
  backend = "remote" {
    hostname = "app.terraform.io"
    organization = "terraform-technical-marketing-demo"
    }
  config {
    path = "terraform-technical-marketing-demo/terraform-aws-dynmaic-secrets-producer"
  }
  }

data "vault_aws_access_credentials" "creds" {
  backend = "${data.terraform_remote_state.producer.backend}"
  role    = "${data.terraform_remote_state.producer.role}"
}

provider "aws" {
  access_key = "${data.vault_aws_access_credentials.creds.access_key}"
  secret_key = "${data.vault_aws_access_credentials.creds.secret_key}"
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create AWS EC2 Instance
resource "aws_instance" "main" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.nano"

  tags {
    Name  = "${var.name}"
    TTL   = "${var.ttl}"
    owner = "${var.name}-guide"
  }
}

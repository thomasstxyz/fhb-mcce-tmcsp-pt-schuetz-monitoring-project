data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

variable ssh_key {
  default = "vockey"
}

resource "aws_instance" "instance-1" {
  ami = data.aws_ami.amazon-2.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.egress-all-all.id,
    aws_security_group.ingress-all-ssh.id,
    aws_security_group.ingress-all-http.id,
  ]

  user_data = templatefile("${path.module}/templates/init_all.tftpl", { PLACEHOLDER = "placeholder" })

  key_name = "${var.ssh_key}"

  tags = {
    Name = "instance-1"
  }
}

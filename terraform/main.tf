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

resource "aws_instance" "kube-master" {
  ami = data.aws_ami.amazon-2.id
  instance_type = "t3.medium"

  vpc_security_group_ids = [
    aws_security_group.egress-all-all.id,
    aws_security_group.ingress-all-all.id,
    aws_security_group.ingress-all-ssh.id,
    aws_security_group.ingress-all-http.id,
    aws_security_group.ingress-all-kubeapi.id,
  ]

  user_data = templatefile("${path.module}/templates/init_kube-master.tftpl", { PLACEHOLDER = "placeholder" })

  key_name = "${var.ssh_key}"

  tags = {
    Name = "kube-master"
  }
}

resource "aws_instance" "kube-worker" {
  ami = data.aws_ami.amazon-2.id
  instance_type = "t3.medium"

  count = 2

  vpc_security_group_ids = [
    aws_security_group.egress-all-all.id,
    aws_security_group.ingress-all-all.id,
    aws_security_group.ingress-all-ssh.id,
    aws_security_group.ingress-all-http.id,
    aws_security_group.ingress-all-kubeapi.id,
  ]

  user_data = templatefile("${path.module}/templates/init_kube-worker.tftpl", { KUBE_APISERVER_URL = aws_instance.kube-master.private_ip })

  key_name = "${var.ssh_key}"

  tags = {
    Name = "kube-worker-${count.index}"
  }
}

# generate inventory file for Ansible
resource "local_file" "hosts" {
  content = templatefile("${path.module}/templates/hosts.tftpl",
    {
      kube-masters = aws_instance.kube-master.*.public_ip
      kube-workers = aws_instance.kube-worker.*.public_ip
    }
  )
  filename = "../ansible/inventory"
}

data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

data "aws_ami" "ubuntu-focal-x86_64" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

variable ssh_key {
  default = "vockey"
}

resource "aws_instance" "kube-master" {
  ami = data.aws_ami.ubuntu-focal-x86_64.id
  instance_type = "t3.large"
  availability_zone = "us-east-1d"

  vpc_security_group_ids = [
    aws_security_group.egress-all-all.id,
    aws_security_group.ingress-all-all.id,
    aws_security_group.ingress-all-ssh.id,
    aws_security_group.ingress-all-http.id,
    aws_security_group.ingress-all-kubeapi.id,
  ]

  user_data = templatefile("${path.module}/templates/init_kube-master.tftpl", { PLACEHOLDER = "placeholder" })

  key_name = "${var.ssh_key}"

  root_block_device {
    volume_size = 25
  }

  tags = {
    Name = "kube-master"
  }
}

resource "aws_instance" "kube-worker" {
  ami = data.aws_ami.ubuntu-focal-x86_64.id
  instance_type = "t3.large"
  availability_zone = "us-east-1d"

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

  root_block_device {
    volume_size = 25
  }

  tags = {
    Name = "kube-worker-${count.index}"
  }
}

# ebs for kube-master
resource "aws_volume_attachment" "ebs_att-0" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs-0.id
  instance_id = aws_instance.kube-master.id
}

resource "aws_ebs_volume" "ebs-0" {
  availability_zone = "us-east-1d"
  size              = 100
}

# ebs volume for kube-worker[0]
resource "aws_volume_attachment" "ebs_att-1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs-1.id
  instance_id = aws_instance.kube-worker[0].id
}

resource "aws_ebs_volume" "ebs-1" {
  availability_zone = "us-east-1d"
  size              = 100
}

# ebs volume for kube-worker[1]
resource "aws_volume_attachment" "ebs_att-2" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs-2.id
  instance_id = aws_instance.kube-worker[1].id
}

resource "aws_ebs_volume" "ebs-2" {
  availability_zone = "us-east-1d"
  size              = 100
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

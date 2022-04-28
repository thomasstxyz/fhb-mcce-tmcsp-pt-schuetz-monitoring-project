resource "aws_security_group" "egress-all-all" {
  name = "egress-all-all"

  // Terraform removes the default rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// TODO: replace ingress-all-all with specific rules for k3s cluster
resource "aws_security_group" "ingress-all-all" {
  name = "ingress-all-all"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-all-ssh" {
  name = "ingress-all-ssh"
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
}

resource "aws_security_group" "ingress-all-http" {
  name = "ingress-all-http"
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
}

resource "aws_security_group" "ingress-all-kubeapi" {
  name = "ingress-all-kubeapi"
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
  }
}

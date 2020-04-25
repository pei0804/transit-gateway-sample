variable env {}
variable basename {}

variable vpc_id {}
variable subnet_id {}
variable ssh_allowed_cidr {}
variable ping_allowed_cidr {}

variable public_key_path {}
variable private_ip {
  default = null
}

locals {
  ingress_rules = {
    ssh = {
      protocol  = "tcp",
      from_port = 22,
      to_port   = 22,
      cidr      = var.ssh_allowed_cidr
    },
    ping = {
      protocol  = "icmp",
      from_port = 8,
      to_port   = 0,
      cidr      = var.ping_allowed_cidr
    }
  }
}

resource "aws_security_group" ec2 {
  name        = "ec2-sg"
  description = "ec2-sg"
  vpc_id      = var.vpc_id
}

resource aws_security_group_rule egress {
  type              = "egress"
  security_group_id = aws_security_group.ec2.id
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource aws_security_group_rule ingress {
  for_each          = local.ingress_rules
  type              = "ingress"
  security_group_id = aws_security_group.ec2.id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.cidr]
}

resource aws_key_pair bastion_keypair {
  key_name   = "${var.basename}-${var.env}-bastion-keypair"
  public_key = file(var.public_key_path)
}

data aws_subnet subnet {
  id = var.subnet_id
}

resource aws_instance ec2 {
  ami                         = "ami-0ff21806645c5e492"
  instance_type               = "t2.micro"
  availability_zone           = data.aws_subnet.subnet.availability_zone
  monitoring                  = false
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion_keypair.key_name
  tags = {
    Name = "${var.basename}-${var.env}-bastion"
  }
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = var.subnet_id

  private_ip = var.private_ip
}
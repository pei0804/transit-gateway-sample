provider aws {
  profile = var.profile
  version = "2.58.0"
  region  = "ap-northeast-1"
}

variable profile {}
variable env {
  default = "dev"
}
variable basename {
  default = "sandbox"
}
variable name {
  default = "transit-gateway-sample"
}

variable vpc {
  type = map(string)
  default = {
    A = "10.0.0.0/16",
    B = "172.16.0.0/16"
  }
}

module A {
  source = "./modules/vpc"

  env      = var.env
  basename = var.basename
  name     = "A"
  cidr     = var.vpc["A"]
}
module B {
  source = "./modules/vpc"

  env      = var.env
  basename = var.basename
  name     = "B"
  cidr     = var.vpc["B"]
}


locals {
  ssh_allowed_cidr = "0.0.0.0/0"
}

module ec2-in-A {
  source = "./modules/ec2"

  env      = var.env
  basename = "${var.basename}-A"

  vpc_id            = module.A.vpc_id
  subnet_id         = module.A.public_subnet_ids[0]
  ping_allowed_cidr = module.B.cidr
  ssh_allowed_cidr  = local.ssh_allowed_cidr
  public_key_path   = "./mykey.pub"
  private_ip        = "10.0.0.161"
}

module ec2-in-B {
  source = "./modules/ec2"

  env      = var.env
  basename = "${var.basename}-B"

  vpc_id            = module.B.vpc_id
  subnet_id         = module.B.public_subnet_ids[0]
  ping_allowed_cidr = module.A.cidr
  ssh_allowed_cidr  = local.ssh_allowed_cidr
  public_key_path   = "./mykey.pub"
  private_ip        = "172.16.0.107"
}

#################
# Transit Gateway
#################

resource aws_ec2_transit_gateway example {
  vpn_ecmp_support                = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments  = "disable"
}

resource aws_ec2_transit_gateway_route_table example {
  transit_gateway_id = aws_ec2_transit_gateway.example.id
}

module A-attachment {
  source = "./modules/transit-gateway"

  vpc_id                         = module.A.vpc_id
  subnet_ids                     = module.A.public_subnet_ids
  route_table_id                 = module.A.public_route_table_id
  transit_gateway_id             = aws_ec2_transit_gateway.example.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.example.id
  destination_vpc_cidr           = module.B.cidr
}

module B-attachment {
  source = "./modules/transit-gateway"

  vpc_id                         = module.B.vpc_id
  subnet_ids                     = module.B.public_subnet_ids
  route_table_id                 = module.B.public_route_table_id
  transit_gateway_id             = aws_ec2_transit_gateway.example.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.example.id
  destination_vpc_cidr           = module.A.cidr
}

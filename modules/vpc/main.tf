variable env {}
variable basename {}
variable name {}
variable cidr {}

data aws_availability_zones az {}

resource aws_vpc vpc {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.basename}-${var.env}-vpc-${var.name}"
  }
}

resource aws_internet_gateway igw {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.basename}-${var.env}-vpc-${var.name}-igw"
  }
}
resource aws_subnet public {
  count                   = 2
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.basename}-${var.env}-vpc-${var.name}-public-subnet-${count.index + 1}"
  }
}
resource aws_route_table public {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.basename}-${var.env}-vpc-${var.name}-public-subnet-rtb"
  }
}
resource aws_route public {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}
resource aws_route_table_association public {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource aws_network_acl acl {
  vpc_id = aws_vpc.vpc.id

  subnet_ids = aws_subnet.public.*.id

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.basename}-${var.env}-vpc-${var.name}-acl"
  }
}

output vpc_id {
  value = aws_vpc.vpc.id
}
output cidr {
  value = aws_vpc.vpc.cidr_block
}
output public_subnet_ids {
  value = aws_subnet.public.*.id
}
output public_route_table_id {
  value = aws_route_table.public.id
}

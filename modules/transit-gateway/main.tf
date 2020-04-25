variable vpc_id {}
variable subnet_ids {}
variable route_table_id {}
variable transit_gateway_id {}
variable transit_gateway_route_table_id {}
variable destination_vpc_cidr {}

#############
# Attaachment
#############
# それぞれのvpcを繋げただけ
# これだけではルーティングが決まってないので、何もできない
resource aws_ec2_transit_gateway_vpc_attachment this {
  subnet_ids = var.subnet_ids
  transit_gateway_id = var.transit_gateway_id
  vpc_id = var.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

#############
# Route Table
#############
# アタッチメントしたvpcをroute tableに関連付ける
resource aws_ec2_transit_gateway_route_table_association this {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

# アタッチメントしたVPCからルートテーブルに経路を伝播する
resource aws_ec2_transit_gateway_route_table_propagation this {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource aws_route to_trgw {
  route_table_id = var.route_table_id
  transit_gateway_id = var.transit_gateway_id
  destination_cidr_block = var.destination_vpc_cidr
}

output "vpc_id"{
  value=aws_vpc.main.id
}

output "public_subnet_ids"{
  value=[for s in aws_subnet.public:s.id]
}

output "private_subnet_ids"{
  value=[for s in aws_subnet.private:s.id]
}

output "public_route_table"{
  value=aws_route_table.public.id
}

output "private_route_tables"{
  value={for k,v in aws_route_table.private:k=>v.id}
}
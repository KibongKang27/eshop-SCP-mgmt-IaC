## VPC_ID
output "vpc_id" {
  value = scp_vpc.mgmt_vpc.id
}

output "pub_subnet_id" {
  value = scp_subnet.public.id  
}

output "prv_subnet_id" {
  value = scp_subnet.private.id  
}

output "scp_natgw_ip" {
  value = scp_nat_gateway.mgmt_nat.public_ipv4
}

# ## Nat GW IP for var
# output "nat_gateway_ip" {
#   value = scp_nat_gateway.mgmt_nat.id
# }
output "vpc_id" {
    value = module.vpc.vpc_id
}

output "public_subnet_id" {
    value = [module.vpc.pub_subnet_id] 
}

output "private_subnet_id" {
    value = [module.vpc.prv_subnet_id] 
}

output "bastion_nat_ip" {
    value = scp_virtual_server.bastion.nat_ipv4
}

output "admin_ip" {
    value = scp_virtual_server.admin.ipv4
}

output "mgmt_scp_nat_gateway_ip" {
    value = module.vpc.scp_natgw_ip
}

output "region" {
    value =  var.region
}
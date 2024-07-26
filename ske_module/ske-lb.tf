resource "scp_load_balancer" "mgmt_lb" {
    vpc_id             = var.vpc_id
    name               = "eshop_mgmt_lb"
    size               = "SMALL"
    cidr_ipv4          = "192.168.102.0/24"
    description        = "LoadBalancer generated from Terraform"
}
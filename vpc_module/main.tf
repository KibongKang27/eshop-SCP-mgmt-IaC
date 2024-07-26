data "scp_region" "my_region" {}

resource "scp_vpc" "mgmt_vpc" {
  name         = "eshopMgmtVpc"
  description  = "Vpc generated from Terraform"
  region       = var.region
}

resource "scp_subnet" "public" {
  vpc_id       = scp_vpc.mgmt_vpc.id
  name         = "eshopMgmtPuSubnet"
  type         = "PUBLIC"
  cidr_ipv4    = "10.0.10.0/24"
  description  = "public subnet generated from Terraform"

  depends_on    = [scp_nat_gateway.mgmt_nat]
}

resource "scp_nat_gateway" "mgmt_nat" {
    subnet_id = scp_subnet.private.id
    #public_ip_id = 
    description = "NAT GW from Terraform"
}

resource "scp_subnet" "private" {
  vpc_id       = scp_vpc.mgmt_vpc.id
  name         = "eshopMgmtPrSubnet"
  type         = "PRIVATE"
  cidr_ipv4    = "10.0.11.0/24"
  description  = "private subnet generated from Terraform"

  depends_on    = [scp_internet_gateway.mgmt_igw]
}

resource "scp_internet_gateway" "mgmt_igw" {
  vpc_id       = scp_vpc.mgmt_vpc.id
  description  = "Internet GW generated from Terraform"
  igw_type = "SHARED"  # SCP Provider 3.0 적용 후 추가
  depends_on    = [scp_vpc.mgmt_vpc]
}

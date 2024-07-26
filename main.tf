data "http" "get_my_public_ip" {
  url = "https://ifconfig.me"
}

data "scp_region" "region" {}

module "vpc" {
  source = "./vpc_module"
  region = var.region
}

module "ske" {
  
  source = "./ske_module"
  
  region = var.region
  service_zone_id = var.service_zone_id
  prv_subnet_id = module.vpc.prv_subnet_id
  availability_zone = var.availability_zone
  vpc_id = module.vpc.vpc_id
  security_group_id = scp_security_group.mgmt_cluster_sg.id

}

############ SCP Provider 3.0 적용 후

# VM Start
variable "igw_type" {
  default = "SHARED"
}

data "scp_standard_image" "ubuntu_image_vm" {
    service_group = "COMPUTE"
    service       = "Virtual Server"
    region        = var.region
    filter {
        name = "image_name"
        values = ["Ubuntu 20.04"]
        use_regex = true
    }
}

data "scp_key_pairs" "my_scp_key_pairs" {
  key_pair_name = "eshopProd"
}

resource "scp_virtual_server" "bastion" {
    //name_prefix         = "eshopbastion"   # will be rolled back after v1.8.6
    //timezone            = "Asia/Seoul"     # will be rolled back after v1.8.6
    virtual_server_name = "eshopbastion"     # will be deleted after v1.8.6
    admin_account       = "root"
    admin_password      = var.bastion_password
    cpu_count           = 1
    memory_size_gb      = 2
    image_id            = data.scp_standard_image.ubuntu_image_vm.id
    vpc_id              = module.vpc.vpc_id
    subnet_id           = module.vpc.pub_subnet_id

    delete_protection   = false
    contract_discount   = "None"

    os_storage_name     = "eshopBtDisk1"
    os_storage_size_gb  = 100
    os_storage_encrypted = false

    # Key Pair 지정
    key_pair_id = data.scp_key_pairs.my_scp_key_pairs.contents[0].key_pair_id

    #initial_script_content = "/test"
    public_ip_id        = scp_public_ip.bastion_ip.id
    security_group_ids  = [
        scp_security_group.bastion_sg.id 
    ]
    use_dns = true
    state = "RUNNING"
    availability_zone_name = var.availability_zone
}

resource "scp_public_ip" "bastion_ip" {
    description = "Public IP generated from Terraform"
	uplink_type = "INTERNET"  # SCP Provider 3.0 적용 후 추가	
    region      = var.region
}

resource "scp_virtual_server" "admin" {
    //name_prefix         = "eshopadmin"   # will be rolled back after v1.8.6 
    //timezone            = "Asia/Seoul"   # will be rolled back after v1.8.6
    virtual_server_name = "eshopadmin"     # will be deleted after v1.8.6 
    admin_account       = "root"
    admin_password      = var.admin_password
    cpu_count           = 2
    memory_size_gb      = 4
    image_id            = data.scp_standard_image.ubuntu_image_vm.id
    vpc_id              = module.vpc.vpc_id
    subnet_id           = module.vpc.prv_subnet_id

    delete_protection   = false
    contract_discount   = "None"

    os_storage_name     = "eshopAdDisk1"
    os_storage_size_gb  = 100
    os_storage_encrypted = false

    # Key Pair 지정
    key_pair_id = data.scp_key_pairs.my_scp_key_pairs.contents[0].key_pair_id


    initial_script_content = <<EOF
# ubuntu 계정 default passwd 지정
echo 'ubuntu:ubuntu' | chpasswd

# config.sh 생성
mkdir /home/ubuntu/.kube
touch /home/ubuntu/.kube/config.sh
echo '#!/bin/bash' >> /home/ubuntu/.kube/config.sh
echo "export KUBECONFIG=~/.kube/config:~/.kube/mgmt.yaml:~/.kube/eshop.yaml; kubectl config view --flatten > ~/.kube/config; sed -i -e '/^  name: user@/s/.*/  name: mgmt/' -e '/^current-context: user@/s/.*/current-context: mgmt/' ~/.kube/config -e '/^  name: user-public@/s/.*/  name: eshop/' ~/.kube/config; export KUBECONFIG=~/.kube/config" >> /home/ubuntu/.kube/config.sh
chmod 755 /home/ubuntu/.kube/config.sh
chown ubuntu:ubuntu -R /home/ubuntu/.kube

# kubectl 설치
mkdir /home/ubuntu/bin
curl -o /home/ubuntu/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.15/2023-01-11/bin/linux/amd64/kubectl
chmod +x /home/ubuntu/bin/kubectl
echo 'alias cls=clear' >> /home/ubuntu/.bashrc
echo 'export PATH=$PATH:/home/ubuntu/bin' >> /home/ubuntu/.bashrc
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# helm install
curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2

### argocd cli install
curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.28/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# alias 설정
echo 'alias cls=clear' >> /home/ubuntu/.bashrc
echo 'export PATH=$PATH:/home/ubuntu/bin' >> /home/ubuntu/.bashrc
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc    

# alias 추가
echo 'alias mc="kubectl config use-context mgmt"' >> /home/ubuntu/.bashrc
echo 'alias ec="kubectl config use-context eshop"' >> /home/ubuntu/.bashrc

# WhereAmI
echo 'alias wai="kubectl config get-contexts"' >> /home/ubuntu/.bashrc

# ubuntu sudoers 추가
sudo echo 'ubuntu ALL=NOPASSWD:ALL' >> /etc/sudoers
EOF

    security_group_ids = [
        scp_security_group.admin_sg.id 
    ]
    use_dns = true
    state = "RUNNING"
    availability_zone_name = var.availability_zone
/*
    external_storage {
        name            = eshopExtStorage
        product_name    = "SSD"
        storage_size_gb = 10
        encrypted       = false
    }
*/
}

# VM End



# SG Start

resource "scp_security_group" "bastion_sg" {
  vpc_id       = module.vpc.vpc_id
  name         = "eshopMgmtBtSG"
  description  = "eshop management bastion server security group"
}

resource "scp_security_group" "admin_sg" {
  vpc_id       = module.vpc.vpc_id
  name         = "eshopMgmtAdSG"
  description  = "eshop management admin server security group"
}

resource "scp_security_group" "mgmt_cluster_sg" {
  vpc_id       = module.vpc.vpc_id
  name         = "eshopMgmtClSG"
  description  = "eshop management admin server security group"
}


resource "scp_security_group_rule" "admin_rule_tcp" {
    security_group_id = scp_security_group.admin_sg.id 
    direction         = "in"
    description       = "ssh SG rule generated from Terraform"
    addresses_ipv4 = ["10.0.10.0/24"]
    service { type = "all" }
}

resource "scp_security_group_rule" "admin_rule_all" {
    security_group_id = scp_security_group.admin_sg.id 
    direction         = "out"
    description       = "SG out rule generated from Terraform"
    addresses_ipv4 = ["0.0.0.0/0"]
    service { type = "all" }
}

resource "scp_security_group_rule" "bastion_rule_all" {
    security_group_id = scp_security_group.bastion_sg.id 
    direction         = "out"
    description       = "SG out rule generated from Terraform"
    addresses_ipv4 = ["0.0.0.0/0"]
    service { type = "all" }
}

resource "scp_security_group_rule" "mgmt_cluster_rule_all" {
    security_group_id = scp_security_group.mgmt_cluster_sg.id 
    direction         = "out"
    description       = "SG out rule generated from Terraform"
    addresses_ipv4 = ["0.0.0.0/0"]
    service { type = "all" }
}

resource "scp_security_group_rule" "bastion_rule_ssh" {
    security_group_id = scp_security_group.bastion_sg.id 
    direction         = "in"
    description       = "SSH SG rule generated from Terraform"
    addresses_ipv4 = [
                        "${chomp(data.http.get_my_public_ip.response_body)}/32"
                     ]
    service { 
        type = "tcp" 
        value = 22
    }
}

# resource "scp_security_group_rule" "bastion_rule_tcp" {
#     security_group_id = scp_security_group.bastion_sg.id 
#     direction         = "in"
#     description       = "TCP SG rule generated from Terraform"
#     addresses_ipv4 = ["0.0.0.0/0"]
#     service { 
#         type = "tcp" 
#         value = 80
#     }
# }

### argo rollout 을 위해 추가되는 부분 ######
resource "scp_security_group_rule" "bastion-argo-rollout" {
    security_group_id = scp_security_group.bastion_sg.id 
    direction         = "in"
    description       = "TCP argo rollout SG rule generated from Terraform"
    addresses_ipv4 = [
                        "${chomp(data.http.get_my_public_ip.response_body)}/32"
                     ]
    service { 
        type = "tcp" 
        value = 3100
    }
}
############

### VPC Peering 을 위해 추가되는 부분 ######
resource "scp_security_group_rule" "admin_rule_peering" {
    security_group_id = scp_security_group.admin_sg.id 
    direction         = "in"
    description       = "ssh SG rule generated from Terraform"
    addresses_ipv4 = ["192.168.0.0/24"]
    service { 
        type = "tcp" 
        value = 22
    }
}
############

# SG End
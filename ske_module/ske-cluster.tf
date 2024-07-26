resource "scp_file_storage" "mgmt_nfs" {
    product_names      =  ["HDD","MultiAZ"]
    #product_names      =  ["HDD"]
    #file_storage_name  = var.file_storage_name != "" ? var.file_storage_name : "eshop_mgmt_nfs"
    file_storage_name  = "eshop_mgmt_nfs"
    file_storage_protocol = "NFS"
    disk_type          = "HDD"
    service_zone_id    = var.service_zone_id
    multi_availability_zone  = true
}

resource "scp_kubernetes_engine" "mgmt_cluster" {
    name               = "eshop-mgmt-cluster"
    kubernetes_version = "v1.24.8"

    vpc_id             = var.vpc_id
    subnet_id          = var.prv_subnet_id
    security_group_id  = var.security_group_id
    volume_id          = scp_file_storage.mgmt_nfs.id

    cloud_logging_enabled = false
    load_balancer_id   = scp_load_balancer.mgmt_lb.id
    //depends_on         = [scp_file_storage.mgmt_nfs]
}
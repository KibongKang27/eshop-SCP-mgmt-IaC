data "scp_standard_image" "ubuntu_image_k8s" {
    service_group      = "CONTAINER"
    service            = "Kubernetes Engine VM"
    region             = var.region

    filter {
        name           = "image_name"
        values         = ["Ubuntu 18.04 (Kubernetes)-v1.24.8"]
        use_regex      = false
    }
}

resource "scp_kubernetes_node_pool" "pool" {
    name               = "eshop-mgmt-node"
    engine_id          = scp_kubernetes_engine.mgmt_cluster.id
    image_id           = data.scp_standard_image.ubuntu_image_k8s.id
    
    #cpu_count          = 2            # provider version up, 2023-12-22, deprecated
    #memory_size_gb     = 4            # provider version up, 2023-12-22, deprecated
    scale_name         = "s1v2m4"      # provider version up, 2023-12-22, added

    auto_recovery      = true
    auto_scale         = false
    desired_node_count = 2
    min_node_count     = 2
    max_node_count     = 2

    timeouts {
      create = "60m"
    }

    availability_zone_name = var.availability_zone  // AZ1 or AZ2 for HA in MAZ KR-WEST
  
}
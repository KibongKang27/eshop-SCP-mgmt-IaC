variable "bastion_password" {
    default = "eshop123!"
    type = string
    description = "bastion server default password"
}

variable "admin_password" {
    default = "eshop123!"
    type = string
    description = "admin server default password"
}

variable "region" {
    default = null
    type = string
    description = "region for management cluster"
}

variable "service_zone_id" {
    default = null
    type = string
    description = "service_zone_id for file_storage"
}

variable "availability_zone" {
	default = null
	type = string
    description = "az for MAZ region"
}

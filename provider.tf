terraform {
  backend "s3" {
    bucket = "t3tfbackend"                         # 공용 object strorage 의 이름 = t3tfbackend 고정값
    key    = "eshop/<< Knox Portal ID >>/mgmt/terraform.tfstate"  # ex) abc.123
    4번째 라인의 << Knox Portal ID >>를 개인 Knox Portal ID 값으로 치환 후 현재 라인도 같이 삭제합니다. ex) key = "eshop/abc.123/mgmt/terraform.tfstate" -- (provider.tf 4번째 라인 key값 앞부분 치환 && 5번째 라인 전체 삭제)
    #endpoint = "https://obj1.kr-east-1.scp-in.com:8443"     # object storage가 생성된 private endpoint      // 1.6 deprecated
    #endpoint = "https://obj1.kr-east-1.samsungsdscloud.com:8443"     # object storage가 생성된 pub endpoint // 1.6 deprecated
    region = "None"
    endpoints = {
      s3 = "https://obj1.kr-east-1.samsungsdscloud.com:8443" 
    }
    skip_region_validation=true
    skip_credentials_validation=true
    skip_metadata_api_check=true
    force_path_style=true
    skip_s3_checksum=true
    skip_requesting_account_id=true
    profile="scp"
  }

  required_providers {
    scp = {
      #version = "2.3.1"
      #version = "3.0.0" # version up, 2023-11-04
      #version = "3.1.0" # version up, 2023-12-22
      #version = "3.5.1" # version up, 2024-04-25
      #version = "3.5.3" # version up, 2024-06-04
      version = "3.7.1" # version up, 2024-07-19
      source = "SamsungSDSCloud/samsungcloudplatform"
    }
  }
  required_version = ">= 0.13"
}

provider "scp" {
}


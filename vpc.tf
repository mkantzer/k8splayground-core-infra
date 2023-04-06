# used for calculating subnets
module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.cidr_block
  networks = [
    {
      name     = "pvt1"
      new_bits = var.subnet_size
    },
    {
      name     = "pvt2"
      new_bits = var.subnet_size
    },
    {
      name     = "pvt3"
      new_bits = var.subnet_size
    },
    {
      name     = "pub1"
      new_bits = var.subnet_size
    },
    {
      name     = "pub2"
      new_bits = var.subnet_size
    },
    {
      name     = "pub3"
      new_bits = var.subnet_size
    },
  ]
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "k8s-playground-${var.env}"
  cidr = var.cidr_block

  azs             = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c",
  ]
  private_subnets = [
    for k, v in module.subnet_addrs.network_cidr_blocks : v
    if startswith(k, "pvt")
  ]
  public_subnets  = [
    for k, v in module.subnet_addrs.network_cidr_blocks : v
    if startswith(k, "pub")
  ]

  enable_nat_gateway = true
  single_nat_gateway = false
  enable_vpn_gateway = true
  
  enable_ipv6 = true
}

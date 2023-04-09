# used for calculating subnets
module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  version         = "1.0.0"
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
    {
      name     = "intra1"
      new_bits = var.subnet_size
    },
    {
      name     = "intra2"
      new_bits = var.subnet_size
    },
    {
      name     = "intra3"
      new_bits = var.subnet_size
    },
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = local.name
  cidr = var.cidr_block

  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c",
  ]
  private_subnets = [
    for k, v in module.subnet_addrs.network_cidr_blocks : v
    if startswith(k, "pvt")
  ]
  public_subnets = [
    for k, v in module.subnet_addrs.network_cidr_blocks : v
    if startswith(k, "pub")
  ]
  intra_subnets = [
    for k, v in module.subnet_addrs.network_cidr_blocks : v
    if startswith(k, "intra")
  ]

  enable_ipv6        = true
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.name
  }
}

##############################################################
# This module allows the creation of a Virtual Network
##############################################################

data "azurerm_resource_group" "exist_rg" {
  name = var.existing_resource_group_name
}

data "azurerm_virtual_network" "exist_vnet" {
  name                = var.existing_vnet_name
  location            = data.azurerm_resource_group.exist_rg.location
  resource_group_name = data.azurerm_resource_group.exist_rg.name
}

data "azurerm_subnet" "exist_sn_fe" {
  name                = var.existing_subnet_name_fe
  virtual_network_name = data.azurerm_virtual_network.exist_vnet.name
  resource_group_name = data.azurerm_resource_group.exist_rg.name
}

data "azurerm_subnet" "exist_sn_aks" {
  name                = var.existing_subnet_name_aks
  virtual_network_name = data.azurerm_virtual_network.exist_vnet.name
  resource_group_name = data.azurerm_resource_group.exist_rg.name
}

resource "azurerm_route_table" "route_table" {
  for_each = var.route_tables

  name                          = "${data.azurerm_resource_group.exist_rg.name}-${each.key}-routetable"
  location                      = data.azurerm_resource_group.exist_rg.location
  resource_group_name           = data.azurerm_resource_group.exist_rg.name
  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation

  dynamic "route" {
    for_each = (each.value.use_inline_routes ? each.value.routes : {})
    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = try(route.value.next_hop_in_ip_address, null)
    }
  }

  tags = var.resource_tags
}

resource "azurerm_route" "non_inline_route" {
  for_each = local.non_inline_routes

  name                   = each.value.name
  resource_group_name    = data.azurerm_resource_group.exist_rg.name
  route_table_name       = azurerm_route_table.route_table[each.value.table].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = try(each.value.next_hop_in_ip_address, null)
}
// ##############################################################
resource "azurerm_subnet_route_table_association" "association" {
  depends_on = [azurerm_route_table.route_table]
  for_each   = local.route_table_associations

  subnet_id      = data.azurerm_subnet.exist_sn_fe.id
  route_table_id = azurerm_route_table.route_table[each.value].id
}
// ##############################################################
resource "azurerm_route_table" "aks_route_table" {
  for_each = local.aks_route_tables

  lifecycle {
    ignore_changes = [tags]
  }

  name                          = "${data.azurerm_resource_group.exist_rg.name}-aks-${each.key}-routetable"
  resource_group_name           = data.azurerm_resource_group.exist_rg.name
  location                      = data.azurerm_resource_group.exist_rg.location
  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation
}

resource "azurerm_route" "aks_route" {
  for_each = local.aks_routes

  name                   = each.value.name
  resource_group_name    = data.azurerm_resource_group.exist_rg.name
  route_table_name       = azurerm_route_table.aks_route_table[each.value.aks_id].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = try(each.value.next_hop_in_ip_address, null)
}
// ##############################################################
resource "azurerm_subnet_route_table_association" "aks" {
  depends_on = [azurerm_route_table.aks_route_table]
  for_each   = local.aks_subnets

  subnet_id      = data.azurerm_subnet.exist_sn_aks.id
  route_table_id = azurerm_route_table.aks_route_table[each.value.aks_id].id
}
// ##############################################################
resource "azurerm_virtual_network_peering" "peer" {
  for_each = local.peers

  name                         = each.key
  resource_group_name          = data.azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = each.value.id
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}

/*
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.name != null ? var.name : local.name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = var.address_space
  tags                = var.resource_tags
  dns_servers         = var.dns_servers
}

module "subnet" {
  source   = "./subnet"
  for_each = local.subnets

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  resource_tags       = var.resource_tags

  naming_rules         = var.naming_rules
  enforce_subnet_names = local.enforce_subnet_names

  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_type          = each.key
  cidrs                = each.value.cidrs

  enforce_private_link_endpoint_network_policies = each.value.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = each.value.enforce_private_link_service_network_policies

  service_endpoints = each.value.service_endpoints
  delegations       = each.value.delegations

  create_network_security_group = each.value.create_network_security_group
  configure_nsg_rules           = each.value.configure_nsg_rules
  allow_internet_outbound       = each.value.allow_internet_outbound
  allow_lb_inbound              = each.value.allow_lb_inbound
  allow_vnet_inbound            = each.value.allow_vnet_inbound
  allow_vnet_outbound           = each.value.allow_vnet_outbound
}

module "aks_subnet" {
  source   = "./subnet"
  for_each = local.aks_subnets

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  resource_tags       = var.resource_tags

  enforce_subnet_names = false

  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_type          = each.key
  cidrs                = each.value.cidrs

  enforce_private_link_endpoint_network_policies = each.value.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = each.value.enforce_private_link_service_network_policies

  service_endpoints = each.value.service_endpoints
  delegations       = each.value.delegations

  create_network_security_group = false
  configure_nsg_rules           = false
}
*/
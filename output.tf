##############################################################
# This module allows the creation of a Virtual Network
##############################################################

output "exist_vnet_name" {
  description = "Virtual network data object."
  value       = azurerm_virtual_network.exist_vnet.name
}

output "fe_sn_id" {
  description = "Subnet data object."
  value       = azurerm_subnet.exist_sn_fe.id
}

output "aks_sn_id" {
  description = "Subnet data object."
  value       = azurerm_subnet.exist_sn_aks.id
}
  
output "route_tables" {
  description = "Maps of custom route tables."
  value = { for k, v in var.route_tables :
    k => {
      name    = azurerm_route_table.route_table[k].name
      id      = azurerm_route_table.route_table[k].id
      subnets = azurerm_route_table.route_table[k].subnets
    }
  }
}

/*


output "vnet" {
  description = "Virtual network data object."
  value       = azurerm_virtual_network.vnet
}

output "subnet" {
  description = "Map of subnet data objects."
  value = zipmap(
    [for subnet in module.subnet : subnet.name],
    [for subnet in module.subnet : subnet.subnet]
  )
}

output "subnet_nsg_ids" {
  description = "Map of subnet ids to associated network_security_group ids."
  value = zipmap(
    [for subnet in module.subnet : subnet.id],
    [for subnet in module.subnet : subnet.network_security_group_id]
  )
}

output "subnet_nsg_names" {
  description = "Map of subnet names to associated network_security_group names."
  value = zipmap(
    [for subnet in module.subnet : subnet.name],
    [for subnet in module.subnet : subnet.network_security_group_name]
  )
}

output "subnets" {
  description = "Maps of subnet info."
  value = zipmap(
    [for subnet in module.subnet : subnet.subnet.name],
    [for subnet in module.subnet : {
      name                        = subnet.subnet.name
      id                          = subnet.subnet.id
      resource_group_name         = subnet.subnet.resource_group_name
      address_prefixes            = subnet.subnet.address_prefixes
      service_endpoints           = subnet.subnet.service_endpoints
      network_security_group_name = subnet.network_security_group_name
      network_security_group_id   = subnet.network_security_group_id
      virtual_network_name        = azurerm_virtual_network.vnet.name
      virtual_network_id          = azurerm_virtual_network.vnet.id
      # route_table_id = (contains(keys(local.route_table_associations), subnet.subnet.name) ?
      #   azurerm_subnet_route_table_association.association[subnet.subnet.name].route_table_id :
      # null)
    }]
  )
}

output "aks" {
  description = "Virtual network information matching AKS module input."
  value = { for aks_id, info in local.aks_info :
    aks_id => {
      subnets = {
        private = {
          id                          = module.aks_subnet["aks-${aks_id}-private"].subnet.id
          resource_group_name         = module.aks_subnet["aks-${aks_id}-private"].subnet.resource_group_name
          address_prefixes            = module.aks_subnet["aks-${aks_id}-private"].subnet.address_prefixes
          service_endpoints           = module.aks_subnet["aks-${aks_id}-private"].subnet.service_endpoints
          network_security_group_id   = module.aks_subnet["aks-${aks_id}-private"].network_security_group_id
          network_security_group_name = module.aks_subnet["aks-${aks_id}-private"].network_security_group_name
          virtual_network_name        = azurerm_virtual_network.vnet.name
          virtual_network_id          = azurerm_virtual_network.vnet.id
          route_table_id              = azurerm_route_table.aks_route_table[aks_id].id
        }
        public = {
          id                          = module.aks_subnet["aks-${aks_id}-public"].subnet.id
          resource_group_name         = module.aks_subnet["aks-${aks_id}-public"].subnet.resource_group_name
          address_prefixes            = module.aks_subnet["aks-${aks_id}-public"].subnet.address_prefixes
          service_endpoints           = module.aks_subnet["aks-${aks_id}-public"].subnet.service_endpoints
          network_security_group_id   = module.aks_subnet["aks-${aks_id}-public"].network_security_group_id
          network_security_group_name = module.aks_subnet["aks-${aks_id}-public"].network_security_group_name
          virtual_network_name        = azurerm_virtual_network.vnet.name
          virtual_network_id          = azurerm_virtual_network.vnet.id
          route_table_id              = azurerm_route_table.aks_route_table[aks_id].id
        }
      }
      route_table_id = azurerm_route_table.aks_route_table[aks_id].id
    }
  }
}

*/
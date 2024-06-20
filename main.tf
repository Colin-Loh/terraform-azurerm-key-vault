data "azurerm_client_config" "this" {}

data "azurerm_subnet" "this" {
  for_each = can(var.network.subnet_name) ? toset(var.network.subnet_name) : toset([])

  name                 = each.key
  virtual_network_name = var.network.name
  resource_group_name  = var.network.resource_group_name
}

resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.resource_group.location
  resource_group_name         = var.resource_group.name
  enabled_for_disk_encryption = var.enabled_for_disk_encryption
  tenant_id                   = data.azurerm_client_config.this.tenant_id
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
  sku_name                    = var.sku_name
  enable_rbac_authorization   = true
  enabled_for_deployment      = var.enabled_for_deployment

  network_acls {
    bypass         = "AzureServices"
    default_action = length(var.network.subnet_name) > 0 ? "Deny" : "Allow"
    virtual_network_subnet_ids = [
      for subnet in data.azurerm_subnet.this :
      subnet.id
    ]
  }
}

data "azurerm_subnet" "pe" {
  for_each = var.network.private_endpoint.subnet_name != null ? { enabled = true } : {}

  name                 = var.network.private_endpoint.subnet_name
  virtual_network_name = var.network.name
  resource_group_name  = var.network.resource_group_name
}

data "azurerm_private_dns_zone" "pe" {
  for_each = var.network.private_endpoint.private_dns_zone_name != null ? { enabled = true } : {}

  name                = var.network.private_endpoint.private_dns_zone_name
  resource_group_name = var.network.resource_group_name
}

resource "azurerm_private_endpoint" "this" {
  for_each = var.network.private_endpoint.subnet_name != null ? { enabled = true } : {}

  name                          = format("%s-%s", azurerm_key_vault.this.name, "pe")
  resource_group_name           = var.resource_group.name
  location                      = var.resource_group.location
  subnet_id                     = data.azurerm_subnet.pe["enabled"].id
  custom_network_interface_name = format("%s-%s", replace(azurerm_key_vault.this.name, "-", ""), "nic")

  private_dns_zone_group {
    name                 = format("%s-%s", azurerm_key_vault.this.name, "privatednszonegroup")
    private_dns_zone_ids = [data.azurerm_private_dns_zone.pe["enabled"].id]
  }

  private_service_connection {
    name                           = format("%s-%s", azurerm_key_vault.this.name, "pse")
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["Vault"]
  }
}

data "azuread_group" "this" {
  for_each = toset(
    flatten([
      for role_assignment in var.role_assignment :
      role_assignment.ad_groups
    ])
  )

  display_name = each.key
}

resource "azurerm_role_assignment" "this" {
  for_each = merge([
    for role_assignment in var.role_assignment : {
      for ad_group in role_assignment.ad_groups :
      "${ad_group}-${role_assignment.role_definition}" => {
        ad_group        = ad_group
        role_definition = role_assignment.role_definition
      }
    }
  ]...)

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role_definition
  principal_id         = data.azuread_group.this[each.value.ad_group].object_id
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "this" {
  name = "d-auea-rg-sandpitcolin-app"
}

module "key_vault" {
  source = "../.."

  name                        = "d-auea-kv-sandpit-col1"
  enabled_for_deployment      = false
  enabled_for_disk_encryption = false
  sku_name                    = "premium"
  soft_delete_retention_days  = 70

  resource_group = {
    name     = data.azurerm_resource_group.this.name
    location = data.azurerm_resource_group.this.location
  }

  role_assignment = [
    {
      ad_groups       = ["AAD Development SandPitColin Admin", "AAD Development SandPitColin Support"]
      role_definition = "Key Vault Contributor"
    },
    {
      ad_groups       = ["AAD Development SandPitColin Pipeline"]
      role_definition = "Key Vault Crypto Officer"
    }
  ]
}



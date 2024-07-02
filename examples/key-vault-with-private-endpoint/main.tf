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
  soft_delete_retention_days  = 80

  resource_group = {
    name     = data.azurerm_resource_group.this.name
    location = data.azurerm_resource_group.this.location
  }

  network = {
    name                = "d-auea-vn-shared"
    resource_group_name = "d-auea-rg-shared"
    subnet_name         = ["d-auea-sn-sandpitcolin-logicapp"]
    private_endpoint = {
      private_dns_zone_name = "privatelink.vaultcore.azure.net"
      subnet_name           = "d-auea-sn-sandpitcolin-private"
    }
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

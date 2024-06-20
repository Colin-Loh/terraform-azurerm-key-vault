provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "this" {
  name = "d-auea-rg-sandpitcolin-app"
}

module "key_vault" {
  source = "../.."

  name = "d-auea-kv-sandpit-col1"

  resource_group = {
    name     = data.azurerm_resource_group.this.name
    location = data.azurerm_resource_group.this.location
  }
}

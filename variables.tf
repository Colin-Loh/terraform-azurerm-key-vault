variable "name" {
  type        = string
  description = "(Required) The name of the Azure Key Vault."
}

variable "enabled_for_disk_encryption" {
  description = "(Required) Specifies if the Azure Key Vault is enabled for disk encryption."
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "(Required) Specifies if the Azure Key Vault has purge protection enabled."
  type        = bool
  default     = false
}

variable "sku_name" {
  description = "(Required) The SKU name for the Azure Key Vault."
  type        = string
  default     = "standard"
}

variable "enabled_for_deployment" {
  description = "(Required) Specifies if the Azure Key Vault is enabled for deployment."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "(Required) The number of days that items will be retained for recovery in Azure Key Vault once they have been marked as deleted."
  type        = number
  default     = 90
}

variable "network" {
  type = object({
    name                = optional(string, null)
    resource_group_name = optional(string, null)
    subnet_name         = optional(list(string), [])
    private_endpoint = optional(object({
      subnet_name           = optional(string, null)
      private_dns_zone_name = optional(string, null)
    }), {})
  })
  description = <<DESC
    (Optional) Network configurations for the Azure Key Vault.

    Properties:
    - `name` (Optional) - The name of the virtual network.
    - `resource_group_name` (Optional) - The name of the resource group where the virtual network is located.
    - `subnet_name` (Optional) - Names of the subnets intended for service endpoints.
    - `private_endpoint` (Optional) - Configuration for private endpoints including the subnet and DNS zone names.
  DESC
  default     = {}
}

variable "role_assignment" {
  type = list(object({
    ad_groups       = optional(list(string))
    role_definition = optional(string)
  }))
  description = <<DESC
  (Optional) List of objects to configure Key Vault users using RBAC Roles
  Properties: 
  - `ad_groups` (Optional) - A list of AD Groups to grant RBAC to this KeyVault
  - `role_definition` (Optional) - The role definition name to grant to the AD Groups
  DESC

  validation {
    condition = alltrue([
      for assignment in var.role_assignment : contains(
        ["Key Vault Administrator", "Key Vault Certificate User", "Key Vault Certificate Officer", "Key Vault Contributor", "Key Vault Crypto Officer", "Key Vault Crypto Service Encryption User", "Key Vault Crypto Service Release User", "Key Vault Crypto User", "Key Vault Data Access Administrator", "Key Vault Reader", "Key Vault Secrets Officer", "Key Vault Secrets User"],
        assignment.role_definition
      )
    ])
    error_message = "Err: invalid role definition provided."
  }

  default = []
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = <<DESC
    (Required) Resource group details.
    Properties:
    - `name` (Required) - The name of the resource group.
    - `location` (Required) - The location where the resource group should be created.
  DESC
}

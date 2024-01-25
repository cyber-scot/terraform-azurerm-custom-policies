data "azurerm_management_group" "tenant_root_group" {
  count        = var.attempt_read_tenant_root_group == true ? 1 : 0
  display_name = "Tenant Root Group"
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

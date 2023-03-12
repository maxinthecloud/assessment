provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "my_resource_group" {
  name     = "my-resource-group"
  location = "West Europe"
}

resource "azurerm_storage_account" "my_storage_account" {
  name                     = "maxsstorageaccount4assessment"
  resource_group_name      = azurerm_resource_group.my_resource_group.name
  location                 = azurerm_resource_group.my_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "my_app_service_plan" {
  name                = "my-app-service-plan"
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
  kind                = "functionapp"
  reserved = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "my_function_app" {
  name                       = "my-function-app"
  location                   = azurerm_resource_group.my_resource_group.location
  resource_group_name        = azurerm_resource_group.my_resource_group.name
  app_service_plan_id        = azurerm_app_service_plan.my_app_service_plan.id
  storage_account_name       = azurerm_storage_account.my_storage_account.name
  storage_account_access_key = azurerm_storage_account.my_storage_account.primary_access_key

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
  }

  site_config {
    always_on        = true
    linux_fx_version = "DOTNETWORKCORE|3.1"
  }
}

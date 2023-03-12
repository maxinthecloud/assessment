terraform {
  required_version = ">=1.3.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.25.0"
    }
  }

 backend "azurerm" {
    resource_group_name  = "my-resource-group-shared"
    storage_account_name = "sa4maxsassessment"
    container_name       = "tfstate"
    key                  = "assessment.tfstate"
  }

}

provider "azurerm" {
  features {
   
  }
  subscription_id = "77b39371-5b2a-4ef5-b9cd-575863a637de"
}

resource "azurerm_resource_group" "my_resource_group" {
  name     = "${var.project}-${var.environment}"
  location = "West Europe"
}

resource "azurerm_storage_account" "my_storage_account" {
  name                     = "stacc4assessment${var.environment}"
  resource_group_name      = azurerm_resource_group.my_resource_group.name
  location                 = azurerm_resource_group.my_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "my_app_service_plan" {
  name                = "my-app-service-plan-${var.environment}"
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
  os_type             = "Windows"
  sku_name            = "Y1"

}

resource "azurerm_windows_function_app" "my_function_app" {
  name                       = "maxsfuncapp4assessment${var.environment}"
  location                   = azurerm_resource_group.my_resource_group.location
  resource_group_name        = azurerm_resource_group.my_resource_group.name
  service_plan_id            = azurerm_service_plan.my_app_service_plan.id
  storage_account_name       = azurerm_storage_account.my_storage_account.name
  storage_account_access_key = azurerm_storage_account.my_storage_account.primary_access_key

  site_config {
  }
}


data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../function-app"
  output_path = "function-app.zip"
}


locals {
    publish_code_command = "az webapp deployment source config-zip --resource-group ${azurerm_resource_group.my_resource_group.name} --name ${azurerm_windows_function_app.my_function_app.name} --src ${data.archive_file.file_function_app.output_path}"
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [local.publish_code_command]
  triggers = {
    input_json = filemd5(data.archive_file.file_function_app.output_path)
    publish_code_command = local.publish_code_command
  }
}
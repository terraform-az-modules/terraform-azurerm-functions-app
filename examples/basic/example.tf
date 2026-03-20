provider "azurerm" {
  features {}
}

module "functions-app" {
  source = "../../"
}

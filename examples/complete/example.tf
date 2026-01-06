provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current_client_config" {}

locals {
  name          = "clarion"
  environment   = "test"
  label_order   = ["name", "environment"]
  location      = "canadacentral"
  taggedby      = "terraform"
  projectdomain = "Membership"
  costcenter    = "IT12345"
  owner         = "TBC"
}

module "resource_group" {
  source      = "terraform-az-modules/resource-group/azurerm"
  version     = "1.0.3"
  name        = "core"
  environment = "qa"
  location    = "centralindia"
  label_order = ["name", "environment", "location"]
}

module "vnet" {
  source              = "terraform-az-modules/vnet/azurerm"
  version             = "1.0.3"
  name                = "core"
  environment         = "qa"
  label_order         = ["name", "environment", "location"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.0.0.0/16"]
}

module "subnet" {
  source               = "terraform-az-modules/subnet/azurerm"
  version              = "1.0.1"
  environment          = "qa"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name

  subnets = [
    {
      name            = "func-integration"
      subnet_prefixes = ["10.0.1.0/24"]
      delegations = [
        {
          name = "delegation1"
          service_delegations = [{
            name = "Microsoft.Web/serverFarms"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/action"
            ]
          }]
        }
      ]
    },
    {
      name            = "pe-subnet"
      subnet_prefixes = ["10.0.2.0/24"]
    }
  ]
}

module "log-analytics" {
  source              = "terraform-az-modules/log-analytics/azurerm"
  version             = "1.0.2"
  name                = "core"
  environment         = "qa"
  label_order         = ["name", "environment", "location"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
}

module "application-insights" {
  source                     = "terraform-az-modules/application-insights/azurerm"
  version                    = "1.0.1"
  name                       = "core2131"
  environment                = "qa"
  label_order                = ["name", "environment", "location"]
  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  workspace_id               = module.log-analytics.workspace_id
  log_analytics_workspace_id = module.log-analytics.workspace_id
  web_test_enable            = false
}

module "storage" {
  source                        = "terraform-az-modules/storage/azurerm"
  version                       = "1.0.0"
  name                          = "core"
  environment                   = "qa"
  label_order                   = ["name", "environment", "location"]
  resource_group_name           = module.resource_group.resource_group_name
  location                      = module.resource_group.resource_group_location
  public_network_access_enabled = true
  account_kind                  = "StorageV2"
  account_tier                  = "Standard"

  network_rules = [
    {
      default_action             = "Allow"
      ip_rules                   = []
      virtual_network_subnet_ids = []
      bypass                     = ["AzureServices"]
    }
  ]

  # containers_list = [
  #   { name = "func-app", access_type = "private" }
  # ]

  file_shares = [
    { name = "func-app-2", quota = 100 }
  ]
}

module "app-service" {
  source              = "git::https://github.com/terraform-az-modules/terraform-azurerm-app-service.git?ref=feat/app-service"
  depends_on          = [module.vnet, module.subnet]
  enable              = true
  name                = "core"
  environment         = "qa"
  label_order         = ["name", "environment", "location"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  os_type             = "Linux"
  linux_sku_name      = "B1"

  # VNet + PE (keep only what you need)
  enable_private_endpoint                = false
  private_endpoint_subnet_id             = module.subnet.subnet_ids["pe-subnet"]
  public_network_access_enabled          = false
  app_insights_connection_string         = module.application-insights.connection_string
  app_insights_id                        = module.application-insights.app_insights_id
  app_service_vnet_integration_subnet_id = module.subnet.subnet_ids["func-integration"]
  app_insights_instrumentation_key       = module.application-insights.instrumentation_key
  linux_app_stack = {
    type         = "node" # change to "node", "java", etc, as needed
    node_version = "22-lts"
    docker = {
      enabled = false
    }
  }
}

##-----------------------------------------------------------------------------
## Private DNS Zone module call
##-----------------------------------------------------------------------------
module "private_dns" {
  source              = "terraform-az-modules/private-dns/azurerm"
  version             = "1.0.2"
  location            = module.resource_group.resource_group_location
  name                = "dns"
  environment         = "dev"
  resource_group_name = module.resource_group.resource_group_name
  private_dns_config = [
    {
      resource_type = "azure_web_apps"
      vnet_ids      = [module.vnet.vnet_id]
    }
  ]
}

module "function_app" {
  source      = "../.."
  kind        = "Linux"
  name        = "core"
  environment = "qa"
  label_order = ["name", "environment", "location"]

  # basic metadata / tags
  taggedby            = "terraform"
  projectdomain       = "Membership"
  costcenter          = "IT12345"
  owner               = "TBC"
  always_on           = true
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location

  # plan and SKU – let the module create the plan, or pass SKU only
  linux_sku_name    = "B1"
  enable_file_mount = true
  # mandatory dependencies
  storage_account_id            = module.storage.storage_account_id
  storage_account_name          = module.storage.storage_account_name
  storage_account_access_key    = module.storage.storage_primary_access_key
  log_analytics_workspace_id    = module.log-analytics.workspace_id
  enable_private_endpoint       = true
  public_network_access_enabled = false
  private_endpoint_subnet_id    = module.subnet.subnet_ids["pe-subnet"]
  virtual_network_id            = module.vnet.vnet_id
  # if your module supports VNet integration subnet, pass it
  # app settings
  app_settings = {
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = module.storage.storage_primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = "sfs-core-qa-inci"
    # "WEBSITE_CONTENTSHARE"  = module.storage.file_shares
    "FUNCTIONS_WORKER_RUNTIME"              = "node-isolated"
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "22-lts"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application-insights.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = module.application-insights.instrumentation_key
  }

  # storage_account_file_mount = [
  #   {
  #     name         = module.storage.storage_account_name
  #     type         = "AzureBlob"
  #     account_name = module.storage.storage_account_name
  #     access_key   = module.storage.storage_primary_access_key
  #     share_name = module.storage.file_shares["sfs-core-qa-inci"]
  #     mount_path   = "/functions"   # e.g. "/mounts/funcfiles"
  #   }
  # ]
  storage_account_file_mount = [
    {
      name         = "astcoreqainci"
      type         = "AzureFiles" # not AzureBlob for file shares
      account_name = module.storage.storage_account_name
      access_key   = module.storage.storage_primary_access_key
      # share_name   = module.storage.file_shares["sfs-core-qa-inci"] # name of the file share you created
      share_name = "sfs-core-qa-inci"
      mount_path = "/functions"
    }
  ]

  private_dns_zone_ids = module.private_dns.private_dns_zone_ids.azure_web_apps

  site_config = {
    application_stack = "node",
    # version                        = "22-lts"
    functions_extension_version    = "~4"
    node_version                   = "22-lts"
    app_insights_connection_string = module.application-insights.connection_string
    application_insights_key       = module.application-insights.instrumentation_key
    websockets_enabled             = false
  }
}
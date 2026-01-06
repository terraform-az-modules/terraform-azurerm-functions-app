##-----------------------------------------------------------------------------
## Variables
##-----------------------------------------------------------------------------

variable "resource_group_name" {
  type        = string
  default     = null
  description = "The name of the resource group to create the resources in."
}

##-----------------------------------------------------------------------------
## Naming convention
##-----------------------------------------------------------------------------
variable "custom_name" {
  type        = string
  default     = null
  description = "Define your custom name to override default naming convention"
}

variable "resource_position_prefix" {
  type        = bool
  default     = true
  description = <<EOT
Controls the placement of the resource type keyword (e.g., "rg", "rg-lock") in the resource name.

- If true, the keyword is prepended: "rg-core-dev".
- If false, the keyword is appended: "core-dev-rg".

This helps maintain naming consistency based on organizational preferences.
EOT
}

##-----------------------------------------------------------------------------
## Labels
##-----------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "managedby" {
  type        = string
  default     = "terraform-az-modules"
  description = "ManagedBy, eg 'terraform-az-modules'."
}

variable "extra_tags" {
  type        = map(string)
  default     = null
  description = "Variable to pass extra tags."
}

variable "repository" {
  type        = string
  default     = "https://github.com/terraform-az-modules/terraform-azure-nsg"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "location" {
  type        = string
  default     = ""
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "Specifies how the infrastructure/resource is deployed"
}

variable "label_order" {
  type        = list(any)
  default     = ["name", "environment", "location"]
  description = "The order of labels used to construct resource names or tags. If not specified, defaults to ['name', 'environment', 'location']."
}

variable "app_service_plan_id" {
  type        = string
  default     = null
  description = "The ID of the App Service plan to host this Function App on."
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "The ID of the Storage account to connect to this Function App."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "The ID of the Log Analytics workspace to send diagnostic to."
}

variable "app_settings" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "A map of app settings to be configured for this Function App."

  validation {
    condition     = length(setintersection(["AzureWebJobsDashboard__accountName", "AzureWebJobsStorage__accountName"], keys(var.app_settings))) == 0
    error_message = "Storage account must be configured using the \"storage_account_id\" variable."
  }

  validation {
    condition     = length(setintersection(["FUNCTIONS_EXTENSION_VERSION"], keys(var.app_settings))) == 0
    error_message = "Functions extension version must be configured using the \"functions_extension_version\" variable."
  }
}

variable "functions_extension_version" {
  type        = string
  default     = "~4"
  nullable    = false
  description = "Which extension version to use for this Function App."
}

variable "kind" {
  type        = string
  default     = "Linux"
  description = "The kind of Function App to create. Allowed values are \"Linux\" and \"Windows\"."
  validation {
    condition     = contains(["Linux", "Windows"], var.kind)
    error_message = "Kind must be \"Linux\" or \"Windows\"."
  }
}

variable "windows_sku_name" {
  type        = string
  default     = null
  description = "SKU name for Windows service plans"
}

variable "linux_sku_name" {
  type        = string
  default     = null
  description = "SKU name for Linux service plans"
}

variable "key_vault_reference_identity_id" {
  type        = string
  default     = null
  description = "The ID of the managed identity that will be used to fetch app settings sourced from Key Vault."
}

variable "virtual_network_subnet_id" {
  type        = string
  default     = null
  description = "The ID of a virtual network subnet to integrate this Function App with."
}

variable "vnet_route_all_enabled" {
  type        = bool
  default     = false
  description = "Should all outbound traffic have NAT gateways, network security groups and user-defined routes applied?"
}

variable "elastic_instance_minimum" {
  type        = number
  default     = 1
  description = "The minimum number of instances for this Function App. Only supported for Elastic Premium (e.g. \"EP1\") plans."
}

variable "pre_warmed_instance_count" {
  type        = number
  default     = 1
  description = "The number of pre-warmed instances for this Function App. Only supported for Elastic Premium (e.g. \"EP1\") plans."
}

variable "app_scale_limit" {
  type        = number
  default     = 1
  description = "The number of instanstes this Function App can scale to. Only supported for Consumption (e.g. \"Y1\") and Elastic Premium (e.g. \"EP1\") plans."
}

variable "application_stack_dotnet_version" {
  type        = string
  default     = null
  description = "The version of .NET to use for this Function App."
}

variable "application_stack_use_dotnet_isolated_runtime" {
  type        = bool
  default     = false
  description = "Should the .NET process for this Function App use an isolated runtime?"
}

variable "application_stack_java_version" {
  type        = string
  default     = null
  description = "The version of Java to use for this Function App."
}

variable "application_stack_node_version" {
  type        = string
  default     = null
  description = "The version of Node.js to use for this Function App."
}

variable "application_stack_python_version" {
  type        = string
  default     = null
  description = "The version of Python to use for this Function App."
}

variable "application_stack_powershell_core_version" {
  type        = string
  default     = null
  description = "The version of PowerShell Core to use for this Function App."
}

variable "use_32_bit_worker" {
  type        = bool
  default     = true
  description = "Should this Function App use a 32-bit worker process?"
}

variable "ip_restriction_default_action" {
  type        = string
  default     = "Deny"
  nullable    = false
  description = "The default action for traffic that does not match any IP restriction rule. Value must be \"Allow\" or \"Deny\"."

  validation {
    condition     = contains(["Allow", "Deny"], var.ip_restriction_default_action)
    error_message = "IP restriction default action must be \"Allow\" or \"Deny\"."
  }
}

variable "scm_ip_restriction_default_action" {
  type        = string
  default     = "Deny"
  nullable    = false
  description = "The default action for traffic to the Source Control Manager (SCM) that does not match any IP restriction rule. Value must be \"Allow\" or \"Deny\"."

  validation {
    condition     = contains(["Allow", "Deny"], var.scm_ip_restriction_default_action)
    error_message = "SCM IP restriction default action must be \"Allow\" or \"Deny\"."
  }
}

variable "ip_restrictions" {

  type = list(object({
    action                    = optional(string, "Allow")
    ip_address                = optional(string)
    name                      = string
    priority                  = number
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)

    headers = optional(object({
      x_forwarded_for   = optional(list(string))
      x_forwarded_host  = optional(list(string))
      x_azure_fdid      = optional(list(string))
      x_fd_health_probe = optional(list(string))
    }))
  }))

  default     = []
  description = "A list of IP restrictions to be configured for this Function App."
}

variable "identity_ids" {
  type        = list(string)
  default     = []
  description = "A list of IDs of managed identities to be assigned to this Function App."
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Boolean to enable private endpoint for Function App"
}
variable "private_endpoint_subnet_id" {
  type        = string
  default     = ""
  description = "Subnet ID for private endpoint"
}

variable "virtual_network_id" {
  type        = string
  default     = ""
  description = "The name of the virtual network"
}

variable "https_only" {
  type        = bool
  default     = true
  description = "To enable https only"
}

variable "storage_account_access_key" {
  type        = string
  default     = null
  description = "Storage account access key to access backend storage conflicts with storage_uses_managed_identity"
}

variable "storage_account_file_mount" {
  type = list(object({
    name         = string # Name
    type         = string
    account_name = string # Account name
    access_key   = string
    share_name   = string # Storage container / file share
    mount_path   = optional(string)
  }))
}

variable "storage_account_name" {
  type        = string
  default     = null
  description = ""
}

variable "enable_file_mount" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "To enable public network access for function app"
}

variable "taggedby" {
  type        = string
  default     = ""
  description = "Tool or process responsible for creating the resource (e.g. `terraform`)."
}

variable "projectdomain" {
  type        = string
  default     = ""
  description = "High-level project domain (e.g. `Membership`)."
}

variable "projectsubdomain" {
  type        = string
  default     = ""
  description = "Specific subdomain of the project"
}

variable "costcenter" {
  type        = string
  default     = ""
  description = "Cost allocation of the resource (e.g. `IT12345`)."
}

variable "owner" {
  type        = string
  default     = ""
  description = "Team or person responsible for the resource (e.g. `TBC`)."
}

variable "resourcegroup" {
  type        = string
  default     = ""
  description = "Associated resource group name (e.g. `app-rg`)."
}

variable "additional_tags" {
  type        = map(string)
  default     = null
  description = "Additional tags for the resource."
}

variable "linux_worker_count" {
  type        = number
  default     = 1
  description = "Number of linux worker count"
}

variable "windows_worker_count" {
  type        = number
  default     = 1
  description = "Number of linux worker count"
}

variable "builtin_logging_enabled" {
  type        = bool
  default     = true
  description = "Configures `AzureWebJobsDashboard` app setting based on the configured storage setting"
}

variable "minimum_tls_version" {
  type        = number
  default     = 1.2
  description = "Minimum version of TLS required for SSL requests"
}

variable "always_on" {
  type        = bool
  default     = false
  description = "To enable always on for function"
}

variable "storage_uses_managed_identity" {
  type        = bool
  default     = false
  description = "Should the Function App use Managed Identity to access the storage account. Conflicts with storage_account_access_key"
}

variable "func_connection_string" {
  type        = string
  default     = null
  description = "Application Insights connection string for Function App"
}

variable "func_instrumentation_key" {
  type        = string
  default     = null
  description = "Application Insights instrumentation key for Function App"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "private_dns_zone_ids" {
  type        = string
  default     = ""
  description = "Id of the private DNS Zone"
}

variable "os_type" {
  type        = string
  default     = "Linux"
  description = "The O/S type for the App Services to be hosted in this plan. Possible values include `Windows`, `Linux`, and `WindowsContainer`."

  validation {
    condition     = try(contains(["Windows", "Linux", "WindowsContainer"], var.os_type), true)
    error_message = "The `os_type` value must be valid. Possible values are `Windows`, `Linux`, and `WindowsContainer`."
  }
}

variable "app_service_environment_id" {
  type        = string
  default     = null
  description = "The ID of the App Service Environment to create this Service Plan in. Requires an Isolated SKU. Use one of I1, I2, I3 for azurerm_app_service_environment, or I1v2, I2v2, I3v2 for azurerm_app_service_environment_v3"
}

variable "worker_count" {
  type        = number
  default     = null
  description = "The number of Workers (instances) to be allocated."
}

variable "maximum_elastic_worker_count" {
  type        = number
  default     = null
  description = "The maximum number of workers to use in an Elastic SKU Plan. Cannot be set unless using an Elastic SKU."
}

variable "per_site_scaling_enabled" {
  type        = bool
  default     = false
  description = "Should Per Site Scaling be enabled."
}

variable "zone_balancing_enabled" {
  type    = bool
  default = false

  validation {
    condition     = !var.zone_balancing_enabled || (var.worker_count > 1)
    error_message = "zone_balancing_enabled can only be true when worker_count > 1."
  }
}

variable "site_config" {
  type = any
}

variable "enable_cors" {
  type    = bool
  default = false
}

variable "cors" {
  description = "List of CORS configurations for the Function App."
  type = list(object({
    allowed_origins     = list(string)
    support_credentials = optional(bool, false)
  }))
  default = []
}




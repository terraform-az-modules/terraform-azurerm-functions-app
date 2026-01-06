##-----------------------------------------------------------------------------
# Standard Tagging Module – Applies standard tags to all resources for traceability
##-----------------------------------------------------------------------------
module "labels" {
  source          = "terraform-az-modules/tags/azurerm"
  version         = "1.0.2"
  name            = var.custom_name == null ? var.name : var.custom_name
  location        = var.location
  environment     = var.environment
  managedby       = var.managedby
  label_order     = var.label_order
  repository      = var.repository
  deployment_mode = var.deployment_mode
  extra_tags      = var.extra_tags
}

##----------------------------------------------------------------------------- 
## Linux function app resource
##-----------------------------------------------------------------------------
resource "azurerm_linux_function_app" "main" {
  count               = var.enabled && local.is_windows ? 0 : 1
  name                = var.resource_position_prefix ? format("func-%s", local.name) : format("%s-func", local.name)
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main[0].id

  storage_account_name = local.storage_account_name
  # storage_account_access_key = var.storage_account_access_key # Use managed identity instead
  storage_uses_managed_identity = var.storage_uses_managed_identity

  https_only = var.https_only

  public_network_access_enabled = var.public_network_access_enabled

  app_settings                = var.app_settings
  functions_extension_version = var.functions_extension_version

  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  virtual_network_subnet_id = var.virtual_network_subnet_id
  builtin_logging_enabled   = var.builtin_logging_enabled

  # dynamic "storage_account" {
  #   for_each = var.enabled && var.enable_file_mount ? var.storage_account_file_mount : []
  #   content {
  #   name         = storage_account.value.action                         # Name
  #   type         = storage_account.value.type                          # Storage type (or "AzureBlob")
  #   account_name = storage_account.value.action        # Account name
  #   access_key   = storage_account.value.primary_access_key
  #   share_name   = storage_account.value.funcfiles.name      # Storage container / file share
  #   mount_path   = storage_account.value.mount_path               # Mount path
  #   }
  # }
  dynamic "storage_account" {
    for_each = var.enabled && var.enable_file_mount ? var.storage_account_file_mount : []
    content {
      name         = storage_account.value.name # logical name
      type         = try(storage_account.value.type, "AzureFiles")
      account_name = storage_account.value.account_name
      access_key   = storage_account.value.access_key
      share_name   = storage_account.value.share_name # file share or container
      mount_path   = storage_account.value.mount_path
    }
  }


  site_config {
    # Ref: https://learn.microsoft.com/en-us/azure/azure-monitor/app/migrate-from-instrumentation-keys-to-connection-strings

    application_insights_connection_string = var.func_connection_string
    application_insights_key               = var.func_instrumentation_key
    worker_count                           = var.linux_worker_count
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    elastic_instance_minimum               = var.elastic_instance_minimum
    pre_warmed_instance_count              = var.pre_warmed_instance_count
    app_scale_limit                        = var.app_scale_limit
    use_32_bit_worker                      = var.use_32_bit_worker
    ip_restriction_default_action          = var.ip_restriction_default_action
    scm_ip_restriction_default_action      = var.scm_ip_restriction_default_action
    minimum_tls_version                    = var.minimum_tls_version
    always_on                              = var.always_on

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions

      content {
        action                    = ip_restriction.value.action
        headers                   = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
      }
    }
    dynamic "ip_restriction" {
      for_each = var.ip_restrictions

      content {
        action                    = ip_restriction.value.action
        headers                   = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
      }
    }

    dynamic "cors" {
      for_each = var.enabled && var.enable_cors ? var.cors : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    dynamic "application_stack" {
      for_each = local.dotnet_application_stack

      content {
        dotnet_version              = var.application_stack_dotnet_version
        use_dotnet_isolated_runtime = var.application_stack_use_dotnet_isolated_runtime
      }
    }

    dynamic "application_stack" {
      for_each = local.java_application_stack

      content {
        java_version = var.application_stack_java_version
      }
    }

    dynamic "application_stack" {
      for_each = local.node_application_stack

      content {
        node_version = var.application_stack_node_version
      }
    }

    dynamic "application_stack" {
      for_each = local.python_application_stack

      content {
        python_version = var.application_stack_python_version
      }
    }

    dynamic "application_stack" {
      for_each = local.powershell_core_application_stack

      content {
        powershell_core_version = var.application_stack_powershell_core_version
      }
    }
  }

  identity {
    type         = length(var.identity_ids) > 0 ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = local.identity_ids
  }

  tags = module.labels.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to common build settings.
      # These are usually configured in CI/CD pipelines.
    ]

    # Precondition to verify only one or null application stacks are defined.
    # Multiple defined stacks creates a conflict.
    precondition {
      condition = length(compact([
        var.application_stack_dotnet_version,
        var.application_stack_java_version,
        var.application_stack_node_version,
        var.application_stack_python_version,
        var.application_stack_powershell_core_version
      ])) < 2

      error_message = "Multiple application stacks are defined. Number of application stacks defined can only be one or null."
    }
  }
}



##----------------------------------------------------------------------------- 
## Windows function app resource
##-----------------------------------------------------------------------------
resource "azurerm_windows_function_app" "main" {
  count = local.is_windows ? 1 : 0
  # name                = format("func-%s", var.name_postfix)
  name                = var.resource_position_prefix ? format("func-%s", local.name) : format("%s-func", local.name)
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.app_service_plan_id

  storage_account_name = local.storage_account_name
  # storage_account_access_key = var.storage_account_access_key # Use managed identity instead
  storage_uses_managed_identity = var.storage_uses_managed_identity

  https_only = var.https_only

  public_network_access_enabled = var.public_network_access_enabled

  app_settings                = var.app_settings
  functions_extension_version = var.functions_extension_version

  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  virtual_network_subnet_id = var.virtual_network_subnet_id
  builtin_logging_enabled   = var.builtin_logging_enabled

  site_config {
    # Ref: https://learn.microsoft.com/en-us/azure/azure-monitor/app/migrate-from-instrumentation-keys-to-connection-strings
    application_insights_connection_string = var.func_connection_string
    application_insights_key               = var.func_instrumentation_key
    worker_count                           = var.windows_worker_count
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    elastic_instance_minimum               = var.elastic_instance_minimum
    pre_warmed_instance_count              = var.pre_warmed_instance_count
    app_scale_limit                        = var.app_scale_limit
    use_32_bit_worker                      = var.use_32_bit_worker
    ip_restriction_default_action          = var.ip_restriction_default_action
    scm_ip_restriction_default_action      = var.scm_ip_restriction_default_action
    minimum_tls_version                    = var.minimum_tls_version
    always_on                              = var.always_on

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions

      content {
        action                    = ip_restriction.value.action
        headers                   = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
      }
    }

    dynamic "application_stack" {
      for_each = local.dotnet_application_stack

      content {
        dotnet_version              = var.application_stack_dotnet_version
        use_dotnet_isolated_runtime = var.application_stack_use_dotnet_isolated_runtime
      }
    }

    dynamic "application_stack" {
      for_each = local.java_application_stack

      content {
        java_version = var.application_stack_java_version
      }
    }

    dynamic "application_stack" {
      for_each = local.node_application_stack

      content {
        node_version = var.application_stack_node_version
      }
    }

    dynamic "application_stack" {
      for_each = local.powershell_core_application_stack

      content {
        powershell_core_version = var.application_stack_powershell_core_version
      }
    }
  }

  identity {
    type         = length(var.identity_ids) > 0 ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = local.identity_ids
  }

  tags = module.labels.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to common build settings.
      # These are usually configured in CI/CD pipelines.
    ]

    # Precondition to verify only one or null application stacks are defined.
    # Multiple defined stacks creates a conflict.
    precondition {
      condition = length(compact([
        var.application_stack_dotnet_version,
        var.application_stack_java_version,
        var.application_stack_node_version,
        var.application_stack_powershell_core_version
      ])) < 2

      error_message = "Multiple application stacks are defined. Number of application stacks defined can only be one or null."
    }
  }
}

# Ref: https://github.com/Azure-Samples/functions-storage-managed-identity
resource "azurerm_role_assignment" "main" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.function_app.identity[0].principal_id
}

##-----------------------------------------------------------------------------
## Private Endpoint for function app
##-----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "main" {
  count               = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                = format("pe-%s", local.is_windows ? azurerm_windows_function_app.main[0].name : azurerm_linux_function_app.main[0].name)
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = module.labels.tags
  private_service_connection {
    name                           = format("psc-%s", local.name)
    is_manual_connection           = false
    private_connection_resource_id = local.is_windows ? azurerm_windows_function_app.main[0].id : azurerm_linux_function_app.main[0].id
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = var.resource_position_prefix ? format("func-dzg-%s", local.name) : format("%s-func-dzg", local.name)
    private_dns_zone_ids = [var.private_dns_zone_ids]
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

##----------------------------------------------------------------------------- 
## Data block to retreive private ip of private endpoint.
##-----------------------------------------------------------------------------
data "azurerm_private_endpoint_connection" "main" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.main[0].name
  resource_group_name = var.resource_group_name
}

##-----------------------------------------------------------------------------
## App Service Plan
##-----------------------------------------------------------------------------
resource "azurerm_service_plan" "main" {
  count               = var.enabled ? 1 : 0
  name                = var.resource_position_prefix ? format("asp-m-%s", local.name) : format("%s-m-asp", local.name)
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  # SKU and scale settings depend on os_type and user inputs; use a conditional to pick correct sku_name
  sku_name     = var.os_type == "Linux" ? var.linux_sku_name : var.windows_sku_name
  worker_count = (var.os_type == "Linux" && var.linux_sku_name == "B1" ? null : var.worker_count)
  # Note: worker_count is null for Linux SKU "B1" as it doesn't support specifying worker count.
  maximum_elastic_worker_count = var.maximum_elastic_worker_count
  app_service_environment_id   = var.app_service_environment_id
  per_site_scaling_enabled     = var.per_site_scaling_enabled
  zone_balancing_enabled       = var.zone_balancing_enabled
  tags                         = module.labels.tags
}

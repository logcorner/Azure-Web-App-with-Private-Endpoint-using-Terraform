resource "azurerm_resource_group" "res-0" {
  location = "eastus"
  name     = "CreatePrivateEndpointQS-rg"
}

resource "azurerm_virtual_network" "res-13" {
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  name                = "MyVNet"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}
resource "azurerm_subnet" "res-14" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "AzureBastionSubnet"
  resource_group_name  = "CreatePrivateEndpointQS-rg"
  virtual_network_name = "MyVNet"
  depends_on = [
    azurerm_virtual_network.res-13,
  ]
}
resource "azurerm_subnet" "res-15" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "myBackendSubnet"
  resource_group_name  = "CreatePrivateEndpointQS-rg"
  virtual_network_name = "MyVNet"
  depends_on = [
    azurerm_virtual_network.res-13,
  ]
}

resource "azurerm_network_interface" "res-6" {
  location            = "eastus"
  name                = "myNicVM"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.res-15.id
  }
  depends_on = [
    azurerm_subnet.res-15,
  ]
}

resource "azurerm_windows_virtual_machine" "res-1" {
  admin_password        = "Gophette1#12"
  admin_username        = "logcorner"
  location              = "eastus"
  name                  = "myVM"
  network_interface_ids = [azurerm_network_interface.res-6.id]
  resource_group_name   = "CreatePrivateEndpointQS-rg"
  size                  = "Standard_DS1_v2"
  # boot_diagnostics {
  #   storage_account_uri = "https://microcreatemyvm041719430.blob.core.windows.net/"
  # }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-6
  ]
}
# resource "azurerm_virtual_machine_extension" "res-2" {
#   auto_upgrade_minor_version = true
#   automatic_upgrade_enabled  = true
#   name                       = "AzurePolicyforWindows"
#   publisher                  = "Microsoft.GuestConfiguration"
#   type                       = "ConfigurationforWindows"
#   type_handler_version       = "1.1"
#   virtual_machine_id         = "/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourceGroups/CreatePrivateEndpointQS-rg/providers/Microsoft.Compute/virtualMachines/myVM"
#   depends_on = [
#     azurerm_windows_virtual_machine.res-1,
#   ]
# }
# resource "azurerm_virtual_machine_extension" "res-3" {
#   auto_upgrade_minor_version = true
#   name                       = "BGInfo"
#   publisher                  = "Microsoft.Compute"
#   type                       = "BGInfo"
#   type_handler_version       = "2.2"
#   virtual_machine_id         = "/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourceGroups/CreatePrivateEndpointQS-rg/providers/Microsoft.Compute/virtualMachines/myVM"
#   depends_on = [
#     azurerm_windows_virtual_machine.res-1,
#   ]
# }
# resource "azurerm_virtual_machine_extension" "res-4" {
#   name                 = "WindowsAgent.AzureSecurityCenter"
#   publisher            = "Qualys"
#   settings             = "{\"GrayLabel\":{\"CustomerID\":\"8efb48e5-2676-4ac5-b85f-7a49fe6205aa\",\"ResourceID\":\"eff1edb6-bdc6-73c6-ffc4-5d134294bd3e\"},\"LicenseCode\":\"eyJjaWQiOiI0ZTdkMGQwMy1mZjdkLTRlNGQtODNlZi0yMmIzMDk1ZTk0ZWQiLCJhaWQiOiJiODYwNWNkYi04OTlmLTQxZDEtOWRmNS05ZTRjOGQ0NDEzNTAiLCJwd3NVcmwiOiJodHRwczovL3FhZ3B1YmxpYy5xZzMuYXBwcy5xdWFseXMuY29tL0Nsb3VkQWdlbnQvIiwicHdzUG9ydCI6IjQ0MyJ9\"}"
#   type                 = "WindowsAgent.AzureSecurityCenter"
#   type_handler_version = "1.0"
#   virtual_machine_id   = "/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourceGroups/CreatePrivateEndpointQS-rg/providers/Microsoft.Compute/virtualMachines/myVM"
#   depends_on = [
#     azurerm_windows_virtual_machine.res-1,
#   ]
# }

resource "azurerm_public_ip" "res-12" {
  allocation_method   = "Static"
  location            = "eastus"
  name                = "myBastionIP"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}
resource "azurerm_bastion_host" "res-5" {
  location            = "eastus"
  name                = "myBastion"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  ip_configuration {
    name                 = "IpConf"
    public_ip_address_id = "/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourceGroups/CreatePrivateEndpointQS-rg/providers/Microsoft.Network/publicIPAddresses/myBastionIP"
    subnet_id            = "/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourceGroups/CreatePrivateEndpointQS-rg/providers/Microsoft.Network/virtualNetworks/MyVNet/subnets/AzureBastionSubnet"
  }
  depends_on = [
    azurerm_public_ip.res-12,
    azurerm_subnet.res-14,
  ]
}

#####  WEB APP

resource "azurerm_service_plan" "res-22" {
  location            = "eastus"
  name                = "ASP-CreatePrivateEndpointQSrg-bca1"
  os_type             = "Linux"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  sku_name            = "P1v3"
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_linux_web_app" "res-23" {
  # app_settings = {
  #   APPINSIGHTS_INSTRUMENTATIONKEY             = "92c100d8-92d6-4278-b2bd-ad536cca2511"
  #   APPLICATIONINSIGHTS_CONNECTION_STRING      = "InstrumentationKey=92c100d8-92d6-4278-b2bd-ad536cca2511;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/"
  #   ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  #   XDT_MicrosoftApplicationInsights_Mode      = "Recommended"
  # }
  https_only          = true
  location            = "eastus"
  name                = "logcornerpewebapp"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  service_plan_id     = azurerm_service_plan.res-22.id
  site_config {
    ftps_state = "FtpsOnly"
  }
  depends_on = [
    azurerm_service_plan.res-22,
  ]
}

################# Create a Private Endpoint

resource "azurerm_private_dns_zone" "res-8" {
  name                = "privatelink.Azurewebsites.net"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}

resource "azurerm_private_endpoint" "res-10" {
  location            = "eastus"
  name                = "myPrivateEndpoint"
  resource_group_name = "CreatePrivateEndpointQS-rg"
  subnet_id           = azurerm_subnet.res-15.id
  private_dns_zone_group {
    name                 = "myZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.res-8.id]
  }
  private_service_connection {
    is_manual_connection           = false
    name                           = "myConnection"
    private_connection_resource_id = azurerm_linux_web_app.res-23.id
    subresource_names              = ["sites"]
  }
  depends_on = [
    azurerm_subnet.res-15,
    azurerm_linux_web_app.res-23,
  ]
}

# resource "azurerm_network_interface" "res-7" {
#   location            = "eastus"
#   name                = "myPrivateEndpoint.nic.ba3a177f-ac3e-48bc-8c98-a8886691d995"
#   resource_group_name = "CreatePrivateEndpointQS-rg"
#   ip_configuration {
#     name                          = "privateEndpointIpConfig.675812f6-6fcc-4625-b03c-a7dd75c810ce"
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = "/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourceGroups/CreatePrivateEndpointQS-rg/providers/Microsoft.Network/virtualNetworks/MyVNet/subnets/myBackendSubnet"
#   }
#   depends_on = [
#     azurerm_subnet.res-15,
#   ]
# }

resource "azurerm_private_dns_zone_virtual_network_link" "res-9" {
  name                  = "myLink"
  private_dns_zone_name = azurerm_private_dns_zone.res-8.name
  resource_group_name   = "CreatePrivateEndpointQS-rg"
  virtual_network_id    = azurerm_virtual_network.res-13.id
  depends_on = [
    azurerm_private_dns_zone.res-8,
    azurerm_virtual_network.res-13,
  ]
}



# resource "azurerm_storage_account" "res-16" {
#   account_replication_type = "GRS"
#   account_tier             = "Standard"
#   location                 = "eastus"
#   min_tls_version          = "TLS1_0"
#   name                     = "microcreatemyvm041719430"
#   resource_group_name      = "CreatePrivateEndpointQS-rg"
#   depends_on = [
#     azurerm_resource_group.res-0,
#   ]
# }
# resource "azurerm_storage_container" "res-18" {
#   name                 = "bootdiagnostics-myvm-c03296c0-a6da-45ad-9109-9af3af269e9e"
#   storage_account_name = "microcreatemyvm041719430"
# }

# resource "azurerm_app_service_custom_hostname_binding" "res-27" {
#   app_service_name    = azurerm_linux_web_app.res-23.name
#   hostname            = "logcornerpewebapp.azurewebsites.net"
#   resource_group_name = "CreatePrivateEndpointQS-rg"
#   depends_on = [
#     azurerm_linux_web_app.res-23,
#   ]
# }
# resource "azurerm_monitor_smart_detector_alert_rule" "res-48" {
#   description         = "Failure Anomalies notifies you of an unusual rise in the rate of failed HTTP requests or dependency calls."
#   detector_type       = "FailureAnomaliesDetector"
#   frequency           = "PT1M"
#   name                = "Failure Anomalies - logcornerpewebapp"
#   resource_group_name = "CreatePrivateEndpointQS-rg"
#   scope_resource_ids  = ["/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourcegroups/createprivateendpointqs-rg/providers/microsoft.insights/components/logcornerpewebapp"]
#   severity            = "Sev3"
#   action_group {
#     ids = [azurerm_monitor_action_group.res-49.id]
#   }
#   depends_on = [
#     azurerm_resource_group.res-0,
#   ]
# }
# resource "azurerm_monitor_action_group" "res-49" {
#   name                = "Application Insights Smart Detection"
#   resource_group_name = "CreatePrivateEndpointQS-rg"
#   short_name          = "SmartDetect"
#   arm_role_receiver {
#     name                    = "Monitoring Contributor"
#     role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
#     use_common_alert_schema = true
#   }
#   arm_role_receiver {
#     name                    = "Monitoring Reader"
#     role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
#     use_common_alert_schema = true
#   }
#   depends_on = [
#     azurerm_resource_group.res-0,
#   ]
# }
# resource "azurerm_application_insights" "res-50" {
#   application_type    = "web"
#   location            = "eastus"
#   name                = "logcornerpewebapp"
#   resource_group_name = "CreatePrivateEndpointQS-rg"
#   sampling_percentage = 0
#   workspace_id        = "/subscriptions/023b2039-5c23-44b8-844e-c002f8ed431d/resourceGroups/DefaultResourceGroup-WEU/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-023b2039-5c23-44b8-844e-c002f8ed431d-WEU"
#   depends_on = [
#     azurerm_resource_group.res-0,
#   ]
# }
# resource "azurerm_private_dns_a_record" "res-51" {
#   name                = "logcornerpewebapp"
#   records             = ["10.0.0.5"]
#   resource_group_name = "createprivateendpointqs-rg"
#   tags = {
#     creator = "created by private endpoint myPrivateEndpoint with resource guid 9d618b81-8494-41d7-a47c-3cea4eaca3af"
#   }
#   ttl       = 10
#   zone_name = "privatelink.azurewebsites.net"
#   depends_on = [
#     azurerm_private_dns_zone.res-8,
#   ]
# }
# resource "azurerm_private_dns_a_record" "res-52" {
#   name                = "logcornerpewebapp.scm"
#   records             = ["10.0.0.5"]
#   resource_group_name = "createprivateendpointqs-rg"
#   tags = {
#     creator = "created by private endpoint myPrivateEndpoint with resource guid 9d618b81-8494-41d7-a47c-3cea4eaca3af"
#   }
#   ttl       = 10
#   zone_name = "privatelink.azurewebsites.net"
#   depends_on = [
#     azurerm_private_dns_zone.res-8,
#   ]
# }

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








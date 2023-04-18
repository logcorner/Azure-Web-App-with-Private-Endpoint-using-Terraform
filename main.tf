resource "azurerm_resource_group" "resource_group" {
  location = "eastus"
  name     = "CreatePrivateEndpointQS-rg"
}

resource "azurerm_virtual_network" "virtual_network" {
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  name                = "MyVNet"
  resource_group_name = azurerm_resource_group.resource_group.name
  depends_on = [
    azurerm_resource_group.resource_group,
  ]
}
resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = "MyVNet"
  depends_on = [
    azurerm_virtual_network.virtual_network,
  ]
}
resource "azurerm_subnet" "backendSubnet" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "myBackendSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = "MyVNet"
  depends_on = [
    azurerm_virtual_network.virtual_network,
  ]
}

resource "azurerm_network_interface" "network_interface" {
  location            = "eastus"
  name                = "myNicVM"
  resource_group_name = azurerm_resource_group.resource_group.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.backendSubnet.id
  }
  depends_on = [
    azurerm_subnet.backendSubnet,
  ]
}

resource "azurerm_windows_virtual_machine" "virtual_machine" {
  admin_password        = "Gophette1#12"
  admin_username        = "logcorner"
  location              = "eastus"
  name                  = "myVM"
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  resource_group_name   = azurerm_resource_group.resource_group.name
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
    azurerm_network_interface.network_interface
  ]
}




resource "azurerm_public_ip" "public_ip" {
  allocation_method   = "Static"
  location            = "eastus"
  name                = "myBastionIP"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.resource_group,
  ]
}
resource "azurerm_bastion_host" "bastion_host" {
  location            = "eastus"
  name                = "myBastion"
  resource_group_name = azurerm_resource_group.resource_group.name
  ip_configuration {
    name                 = "IpConf"
    public_ip_address_id = azurerm_public_ip.public_ip.id
    subnet_id            = azurerm_subnet.subnet.id
  }
  depends_on = [
    azurerm_public_ip.public_ip,
    azurerm_subnet.subnet,
  ]
}

#####  WEB APP

resource "azurerm_service_plan" "service_plan" {
  location            = "eastus"
  name                = "ASP-CreatePrivateEndpointQSrg-bca1"
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "P1v3"
  depends_on = [
    azurerm_resource_group.resource_group
  ]
}
resource "azurerm_linux_web_app" "web_app" {

  https_only          = true
  location            = "eastus"
  name                = "logcornerpewebapp"
  resource_group_name = azurerm_resource_group.resource_group.name
  service_plan_id     = azurerm_service_plan.service_plan.id
  site_config {
    ftps_state = "FtpsOnly"
  }
  depends_on = [
    azurerm_service_plan.service_plan,
  ]
}

################# Create a Private Endpoint

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.Azurewebsites.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  depends_on = [
    azurerm_resource_group.resource_group,
  ]
}

resource "azurerm_private_endpoint" "private_endpoint" {
  location            = "eastus"
  name                = "myPrivateEndpoint"
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_id           = azurerm_subnet.backendSubnet.id
  private_dns_zone_group {
    name                 = "myZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }
  private_service_connection {
    is_manual_connection           = false
    name                           = "myConnection"
    private_connection_resource_id = azurerm_linux_web_app.web_app.id
    subresource_names              = ["sites"]
  }
  depends_on = [
    azurerm_subnet.backendSubnet,
    azurerm_linux_web_app.web_app,
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual_network_link" {
  name                  = "myLink"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name   = azurerm_resource_group.resource_group.name
  virtual_network_id    = azurerm_virtual_network.virtual_network.id
  depends_on = [
    azurerm_private_dns_zone.private_dns_zone,
    azurerm_virtual_network.virtual_network,
  ]
}








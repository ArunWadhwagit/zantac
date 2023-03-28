#Create a Resource Group
resource "azurerm_resource_group" "zantac_rg" {
 name     = "${var.zantac}-rg"
 location = var.location
}
#Create a Virtual Network
resource "azurerm_virtual_network" "zantac_vnet" {
 name                = "${var.zantac}-vnet"
 address_space       = ["10.0.0.0/16"]
 location            = azurerm_resource_group.zantac_rg.location
 resource_group_name = azurerm_resource_group.zantac_rg.name
}
#Create a subnet
resource "azurerm_subnet" "zantac_subnet" {
 name                 = "${var.zantac}-subnet"
 resource_group_name  = azurerm_resource_group.zantac_rg.name
 virtual_network_name = azurerm_virtual_network.zantac_vnet.name
 address_prefixes       = ["10.0.2.0/24"]
}
#Create public ip for vmss
resource "azurerm_public_ip" "zantac_vmss_pip" {
 name                         = "${var.zantac}-vmss-pip"
 location                     = azurerm_resource_group.zantac_rg.location
 resource_group_name          = azurerm_resource_group.zantac_rg.name
 allocation_method = "Static"
 sku = "Standard"
}
#Create public ip for nat gateway
resource "azurerm_public_ip" "zantac_nat_gateway_public_ip" {
  name                = "${var.zantac}-nat-gateway-pip"
  location            = azurerm_resource_group.zantac_rg.location
  resource_group_name = azurerm_resource_group.zantac_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}
#Create a nat gateway
resource "azurerm_nat_gateway" "zantac_nat_gateway" {
  name                    = "${var.zantac}-nat-gateway"
  location                = azurerm_resource_group.zantac_rg.location
  resource_group_name     = azurerm_resource_group.zantac_rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}
#Associate the public IP address with the NAT gateway
resource "azurerm_nat_gateway_public_ip_association" "zantac_nat_gateway_public_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.zantac_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.zantac_nat_gateway_public_ip.id
}
#Create a subnet nat gateway association
resource "azurerm_subnet_nat_gateway_association" "zantac_subnet_nat_gateway_association" {
  subnet_id      = azurerm_subnet.zantac_subnet.id
  nat_gateway_id = azurerm_nat_gateway.zantac_nat_gateway.id
}
#Create a network security group
resource "azurerm_network_security_group" "zantac_nsg" {
  name                = "${var.zantac}-nsg"
  location            = azurerm_resource_group.zantac_rg.location
  resource_group_name = azurerm_resource_group.zantac_rg.name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_HTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_Ssh"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
#Create a load balancer
resource "azurerm_lb" "zantac_lb" {
 name                = "${var.zantac}-lb"
 location            = azurerm_resource_group.zantac_rg.location
 resource_group_name = azurerm_resource_group.zantac_rg.name
 sku = "Standard"

 frontend_ip_configuration {
   name                 = "PublicIPAddress"
   public_ip_address_id = azurerm_public_ip.zantac_vmss_pip.id
 }
}
#Create a backend pool
resource "azurerm_lb_backend_address_pool" "bpepool" {
 
 loadbalancer_id     = azurerm_lb.zantac_lb.id
 name                = "BackEndAddressPool"
}
#Create load balancer probe
resource "azurerm_lb_probe" "zantac_probe" {
 loadbalancer_id     = azurerm_lb.zantac_lb.id
 name                = "zantac-running-probe"
 port                = 80
}
#Create load balancer rule
resource "azurerm_lb_rule" "zantac_lb_rule" {
   loadbalancer_id                = azurerm_lb.zantac_lb.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = 80
   backend_port                   = 80
   backend_address_pool_ids        = [azurerm_lb_backend_address_pool.bpepool.id]
   frontend_ip_configuration_name = "PublicIPAddress"
   probe_id                       = azurerm_lb_probe.zantac_probe.id
}
#Create inbound nat rule for 80 port
resource "azurerm_lb_nat_rule" "zantac_nat_rule_01" {
  resource_group_name            = azurerm_resource_group.zantac_rg.name
  loadbalancer_id                = azurerm_lb.zantac_lb.id
  name                           = "zantac-nat-rule-01"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50099
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = azurerm_lb.zantac_lb.frontend_ip_configuration.0.name
}
#Create inbound nat rule for 22 port
resource "azurerm_lb_nat_rule" "zantac_nat_rule_02" {
  resource_group_name            = azurerm_resource_group.zantac_rg.name
  loadbalancer_id                = azurerm_lb.zantac_lb.id
  name                           = "zantac-nat-rule-02"
  protocol                       = "Tcp"
  frontend_port_start            = 30000
  frontend_port_end              = 30099
  backend_port                   = 22
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = azurerm_lb.zantac_lb.frontend_ip_configuration.0.name
}
#Create inbound nat rule for 8080 port
resource "azurerm_lb_nat_rule" "zantac_nat_rule_03" {
  resource_group_name            = azurerm_resource_group.zantac_rg.name
  loadbalancer_id                = azurerm_lb.zantac_lb.id
  name                           = "zantac-nat-rule-03"
  protocol                       = "Tcp"
  frontend_port_start            = 40000
  frontend_port_end              = 40099
  backend_port                   = 8080
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = azurerm_lb.zantac_lb.frontend_ip_configuration.0.name
}
#Create a virtual machine scale set
resource "azurerm_virtual_machine_scale_set" "zantac_vmss" {
 name                = "${var.zantac}-vmss"
 location            = azurerm_resource_group.zantac_rg.location
 resource_group_name = azurerm_resource_group.zantac_rg.name
 upgrade_policy_mode = "Manual"

 zones = local.zones

 sku {
   name     = "Standard_B1S"
   tier     = "Standard"
   capacity = 2
 }
 tags = {
  tag_group_vmss = "my-vmss-group"
 }

 storage_profile_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_profile_os_disk {
   name              = ""
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 storage_profile_data_disk {
   lun          = 0
   caching        = "ReadWrite"
   create_option  = "Empty"
   disk_size_gb   = 10
 }

 os_profile {
   computer_name_prefix = "vmlab"
   admin_username       = "arwadhwa"
   custom_data          = file("web.conf")
 }

 os_profile_linux_config {
   disable_password_authentication = true
   ssh_keys {
      path     = "/home/arwadhwa/.ssh/authorized_keys"
      key_data = file("C:/Users/DELL/Desktop/publicis_Exercise/web_server_tf_code/mykey.pem.pub")
    }
  }
 network_profile {
   name    = "terraformnetworkprofile"
   primary = true
   network_security_group_id = azurerm_network_security_group.zantac_nsg.id

   ip_configuration {
     name                                   = "IPConfiguration"
     subnet_id                              = azurerm_subnet.zantac_subnet.id
     load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
     primary = true
   }
 }
}
#Create  an autoscale setting
resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "${var.zantac}-autoscale"
  resource_group_name = azurerm_resource_group.zantac_rg.name
  location            = azurerm_resource_group.zantac_rg.location
  target_resource_id  = azurerm_virtual_machine_scale_set.zantac_vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.zantac_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.zantac_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["arun.wadhwa88@gmail.com"]
    }
  }
}
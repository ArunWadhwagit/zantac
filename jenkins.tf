# # Create a resource group
# resource "azurerm_resource_group" "jenkinsrg" {
#   name     = "jenkins-resource-group"
#   location = "East US"
# }

# # Create a virtual network
# resource "azurerm_virtual_network" "jenkinsvnet" {
#   name                = "jenkins-virtual-network"
#   address_space       = ["10.0.0.0/16"]
#   location            = azurerm_resource_group.jenkinsrg.location
#   resource_group_name = azurerm_resource_group.jenkinsrg.name
# }

# # Create a subnet
# resource "azurerm_subnet" "jenkinssubnet" {
#   name                 = "jenkins-subnet"
#   resource_group_name  = azurerm_resource_group.jenkinsrg.name
#   virtual_network_name = azurerm_virtual_network.jenkinsvnet.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# # Create a public IP address
# resource "azurerm_public_ip" "jenkinspip" {
#   name                = "jenkins-public-ip"
#   location            = azurerm_resource_group.jenkinsrg.location
#   resource_group_name = azurerm_resource_group.jenkinsrg.name
#   allocation_method   = "Dynamic"
# }

# # Create a network interface
# resource "azurerm_network_interface" "jenkinsnic" {
#   name                = "jenkins-network-interface"
#   location            = azurerm_resource_group.jenkinsrg.location
#   resource_group_name = azurerm_resource_group.jenkinsrg.name

#   ip_configuration {
#     name                          = "jenkins-ip-configuration"
#     subnet_id                     = azurerm_subnet.jenkinssubnet.id
#     public_ip_address_id          = azurerm_public_ip.jenkinspip.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }
# #Create a network security group
# resource "azurerm_network_security_group" "jenkins_nsg" {
#   name                = "${var.zantac}-nsg"
#   location            = azurerm_resource_group.jenkinsrg.location
#   resource_group_name = azurerm_resource_group.jenkinsrg.name

#   security_rule {
#     name                       = "Allow_HTTP"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_HTTPS"
#     priority                   = 101
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "8080"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_Ssh"
#     priority                   = 200
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }
# resource "azurerm_subnet_network_security_group_association" "jenkinsnsgassociation" {
#   subnet_id                 = azurerm_subnet.jenkinssubnet.id
#   network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
# }
# # Create a virtual machine
# resource "azurerm_virtual_machine" "jenkins" {
#   name                  = "jenkins-virtual-machine"
#   location              = azurerm_resource_group.jenkinsrg.location
#   resource_group_name   = azurerm_resource_group.jenkinsrg.name
#   network_interface_ids = [azurerm_network_interface.jenkinsnic.id]
#   vm_size               = "Standard_B2s"

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   storage_os_disk {
#     name              = "jenkins-os-disk"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }

#   os_profile {
#     computer_name  = "jenkinsvm"
#     admin_username = "adminuser"
#     admin_password = "P@ssw0rd1234!"
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-get update",
#       "sudo apt-get install -y openjdk-8-jdk",
#       "sudo wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -",
#       "sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
#       "sudo apt-get update",
#       "sudo apt-get install -y jenkins",
#       "sudo systemctl start jenkins"
#     ]
#   }
# }

# # Output the public IP address of the virtual machine
# output "public_ip_address" {
#   value = azurerm_public_ip.jenkinspip.ip_address
# }

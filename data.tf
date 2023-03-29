terraform {
  backend "azurerm" {
    storage_account_name = "terraformstudevops"                                                                     
    container_name       = "tfstatedevops"                                                                                
    key                  = "resources.tfstate"                                                                  
    access_key           = "UddwMYs9FllfO3vf+aAZXm1X8zVtJ/BnBskaF8KNkWF/RAdXpKrLAAU6cTUj41uqekngKOFWAJyb+AStpVYiOw==" 
  }
}
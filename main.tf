terraform {
    #Define the required providers for the deployment
    required_providers {
        azurerm = {
            source  = "azurerm"
            version = "=2.13.0"
        }
    }
}

#Configure azure provider
provider "azurerm" {
    features {}
}
terraform {
    required_providers {
        azure = {
        source  = "azurerm"
        version = "=2.13.0"
        }
    }
}


provider "azure" {
    features {}
}

resource "azurerm_resource_group" "jenkins" {
    name     = "rg-jenkins"
    location = "West Europe"

    tags = {
        environment = "Jenkins Test"
    }
}

resource "azurerm_virtual_network" "jenkins" {
    name                = "vnet-common"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.jenkins.location
    resource_group_name = azurerm_resource_group.jenkins.name

    tags = {
        environment = "Jenkins Test"
    }
}

resource "azurerm_subnet" "jenkins" {
    name                 = "snet-jenkins"
    resource_group_name  = azurerm_resource_group.jenkins.name
    virtual_network_name = azurerm_virtual_network.jenkins.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "jenkins" {
    name                         = "pip-jenkins"
    location                     = azurerm_resource_group.jenkins.location
    resource_group_name          = azurerm_resource_group.jenkins.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Jenkins Test"
    }
}

output "jenkins-public-ip" {
    description = "Public IP of Jenkins VM"
    value       = azurerm_public_ip.jenkins.ip_address
}

resource "azurerm_network_security_group" "jenkins" {
    name                = "nsg-jenkins"
    location            = azurerm_resource_group.jenkins.location
    resource_group_name = azurerm_resource_group.jenkins.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Port-8080"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Jenkins Test"
    }
}

resource "azurerm_network_interface" "jenkins" {
    name                = "nic-jenkins"
    location            = azurerm_resource_group.jenkins.location
    resource_group_name = azurerm_resource_group.jenkins.name

    ip_configuration {
        name                          = "ip-internal"
        subnet_id                     = azurerm_subnet.jenkins.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.jenkins.id
    }

    tags = {
        environment = "Jenkins Test"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.jenkins.id
    network_security_group_id = azurerm_network_security_group.jenkins.id
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.jenkins.name
    }

    byte_length = 8
}

resource "azurerm_storage_account" "diag" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.jenkins.name
    location                    = azurerm_resource_group.jenkins.location
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "Jenkins Test"
    }
}

resource "azurerm_linux_virtual_machine" "jenkins" {
    name                = "vm-jenkins"
    resource_group_name = azurerm_resource_group.jenkins.name
    location            = azurerm_resource_group.jenkins.location
    size                = "Standard_DS1_v2"
    admin_username      = "jenkinsadmin"
    network_interface_ids = [
        azurerm_network_interface.jenkins.id,
    ]

    admin_ssh_key {
        username   = "jenkinsadmin"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    #install Jenkins
    custom_data = filebase64("./cloud-init-jenkins.txt")

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
    }

    tags = {
        environment = "Jenkins Test"
    }
}

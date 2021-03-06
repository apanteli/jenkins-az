resource "azurerm_resource_group" "jenkins" {
    name     = "rg-jenkins"
    location = var.location

    tags = {
        environment = var.environment
    }
}

resource "azurerm_virtual_network" "jenkins" {
    name                = "vnet-common"
    address_space       = var.common_vnet_address_space
    location            = azurerm_resource_group.jenkins.location
    resource_group_name = azurerm_resource_group.jenkins.name

    tags = {
        environment = var.environment
    }
}

resource "azurerm_subnet" "jenkins" {
    name                 = "snet-jenkins"
    resource_group_name  = azurerm_resource_group.jenkins.name
    virtual_network_name = azurerm_virtual_network.jenkins.name
    address_prefixes     = var.jenkins_subnet_address_prefix
}

resource "azurerm_public_ip" "jenkins" {
    name                         = "pip-jenkins"
    location                     = azurerm_resource_group.jenkins.location
    resource_group_name          = azurerm_resource_group.jenkins.name
    allocation_method            = "Dynamic"

    tags = {
        environment = var.environment
    }
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
        name                       = "Jenkins-port"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = var.jenkins_port
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = var.environment
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
        environment = var.environment
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
        environment = var.environment
    }
}

resource "azurerm_linux_virtual_machine" "jenkins" {
    name                = "vm-jenkins"
    resource_group_name = azurerm_resource_group.jenkins.name
    location            = var.location
    size                = var.jenkins_vm_size
    admin_username      = var.jenkins_user
    network_interface_ids = [
        azurerm_network_interface.jenkins.id,
    ]

    admin_ssh_key {
        username   = var.jenkins_user
        public_key = file(var.public_key)
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

    #install Jenkins using cloud-init
    custom_data = filebase64("./cloud-init-jenkins.txt")

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
    }

    tags = {
        environment = var.environment
    }
}
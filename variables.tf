variable "location" {
    type = string
    description = "Location used for the deployment"
    default = "West Europe"
}

variable "jenkins_vm_size" {
    type = string
    description = "Size of Jenkins VM"
    default = "Standard_DS1_v2"
}

variable "common_vnet_address_space" {
    type = list(string)
    description = "Address space of common services vnet"
    default = [
        "10.0.0.0/16"
    ]
}

variable "jenkins_subnet_address_prefix" {
    type = list(string)
    description = "Address prefixes of jenkins subnet"
    default = [
        "10.0.2.0/24"
    ]
}

variable "public_key" {
    type = string
    description = "SSH public key used for Jenkins admin user"
    default = "~/.ssh/id_rsa.pub"
}

variable "private_key" {
    type = string
    description = "SSH private key used for Jenkins admin user"
    default = "~/.ssh/id_rsa"
}

variable "jenkins_user" {
    type = string
    description = "User used as admin for Jenkins VM"
    default = "jenkinsadmin"
}

variable "environment" {
    type = string
    description = "Environment label used to tag resources" 
    default = "jenkins-test"
}

variable "jenkins_port" {
    type = string
    description = "Port used for Jenkins service"
    default = "8080"
}
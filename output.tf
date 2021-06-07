output "jenkins-public-ip" {
    description = "Public IP of Jenkins VM"
    value       = azurerm_public_ip.jenkins.ip_address
}
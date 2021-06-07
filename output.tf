output "jenkins-public-ip" {
    description = "Public IP of Jenkins VM"
    value       = azurerm_public_ip.jenkins.ip_address
}

output "url-jenkins" {
    description = "Jenkins URL"
    value = "http://${azurerm_public_ip.jenkins.ip_address}:8080"
}

output "ssh-jenkins" {
    description = "SSH to jenkins VM"
    value = "ssh -i ${var.private_key} ${var.jenkins_user}@${azurerm_public_ip.jenkins.ip_address}"
}

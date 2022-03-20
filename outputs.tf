output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_share_name" {
  value = azurerm_storage_share.this.name
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}
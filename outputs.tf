output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_share_name" {
  value = azurerm_storage_share.this.name
}

/* 
output "aws_iam_role" {
  value = aws_iam_role.this
}

output "aws_iam_instance_profile" {
  value = aws_iam_instance_profile.this
} */
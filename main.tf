# Create 3 digit random string
resource "random_string" "this" {
  length  = 3
  special = false
  upper   = false
}

# Concatenate with random string to avoid duplication
locals {
  rg_name           = "${var.rg_name}-${random_string.this.id}"
  bootstrap_storage = "${var.bootstrap_storage}${random_string.this.id}"
  bootstrap_share   = "${var.bootstrap_share}${random_string.this.id}"

  bootstrap_folders = toset([
    "config",
    "content",
    "license",
    "software"
  ])
}

# Create a resource group
resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
  tags     = {}
}

# Create an Azure storage account
resource "azurerm_storage_account" "this" {
  name                     = local.bootstrap_storage
  location                 = var.location
  resource_group_name      = azurerm_resource_group.this.name
  min_tls_version          = var.min_tls_version
  account_replication_type = "LRS"
  account_tier             = "Standard"

  depends_on = [azurerm_resource_group.this]
}

# Create a file share in Azure storage account 
resource "azurerm_storage_share" "this" {
  name                 = local.bootstrap_share
  storage_account_name = azurerm_storage_account.this.name
  quota                = 50

  depends_on = [azurerm_storage_account.this]
}

resource "azurerm_storage_share_directory" "bootstrap_folders" {
  for_each = local.bootstrap_folders

  name                 = each.key
  share_name           = azurerm_storage_share.this.name
  storage_account_name = azurerm_storage_account.this.name

  depends_on = [azurerm_storage_share.this]
}

resource "azurerm_storage_share_file" "init-cfg_txt" {
  name             = "init-cfg.txt"
  path             = "config"
  storage_share_id = azurerm_storage_share.this.id
  source           = "${path.module}/init-cfg.txt"
}

data "template_file" "bootstrap_xml" {
  template = file("${path.module}/bootstrap.tmpl")
}

resource "azurerm_storage_share_file" "bootstrap_xml" {
  name             = "bootstrap.xml"
  path             = "config"
  storage_share_id = azurerm_storage_share.this.id
  source           = "${path.module}/bootstrap.xml"
}

/* resource "azurerm_storage_share_file" "bootstrap_xml" {
  name             = "bootstrap.xml"
  path             = "config"
  storage_share_id = azurerm_storage_share.this.id
  source           = data.template_file.bootstrap_xml.rendered
} */

/* resource "azurerm_storage_share_file" "bootstrap_xml" {
  name             = "bootstrap.xml"
  path             = "config"
  storage_share_id = azurerm_storage_share.this.id
  #source           = "${path.module}/bootstrap.xml.tmpl"
  source = templatefile("${path.module}/bootstrap.xml.tmpl",
    {
      "config_version"           = var.config_version,
      "detail_version"           = var.detail_version,
      "admin_user"               = var.admin_user,
      "admin_password_phash"     = var.admin_password_phash,
      "admin_public_key"         = var.admin_public_key,
      "admin_api_user"           = var.admin_api_user,
      "admin_api_profile_name"   = var.admin_api_profile_name,
      "admin_api_password_phash" = var.admin_api_password_phash
    }
  )
} */



/* resource "azurerm_storage_share_directory" "config" {
  name                 = "config"
  share_name           = azurerm_storage_share.this.name
  storage_account_name = azurerm_storage_account.this.name
} */

/* resource "azurerm_storage_share_file" "this" {
  for_each = var.files

  name             = regex("[^/]*$", each.value)
  path             = replace(each.value, "/[/]*[^/]*$/", "")
  storage_share_id = azurerm_storage_share.this.id
  source           = replace(each.key, "/CalculateMe[X]${random_id.this[each.key].id}/", "CalculateMeX${random_id.this[each.key].id}")
  # Live above is equivalent to:   `source = each.key`  but it re-creates the file every time the content changes.
  # The replace() is not actually doing anything, except tricking Terraform to destroy a resource.
  # There is a field content_md5 designed specifically for that. But I see a bug in the provider (last seen in 2.76):
  # When content_md5 changes the re-uploading seemingly succeeds, result being however a totally empty file (size zero).
  # Workaround: use random_id above to cause the full destroy/create of a file.
  depends_on = [azurerm_storage_share_directory.config, azurerm_storage_share_directory.nonconfig]
} */
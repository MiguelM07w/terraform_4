resource "azurerm_network_interface" "worker" {
  name                           = var.vm.network_interface_name
  resource_group_name            = local.resource_group_name
  location                       = local.location
  accelerated_networking_enabled = true
  tags                           = local.tags

  # Sin IP pública: la administración se realiza exclusivamente por Bastion.
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = local.network.subnet_ids["vm"]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "worker" {
  name                  = var.vm.name
  resource_group_name   = local.resource_group_name
  location              = local.location
  size                  = var.vm.size
  zone                  = var.vm.zone
  network_interface_ids = [azurerm_network_interface.worker.id]

  # Acceso solo con llave SSH; la llave privada nunca sale de la estación del
  # administrador.
  admin_username                  = var.vm.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm.admin_username
    public_key = file(pathexpand(var.vm.ssh_public_key_path))
  }

  # Trusted Launch: arranque seguro y vTPM.
  secure_boot_enabled = true
  vtpm_enabled        = true

  # Identidad para obtener tokens de PostgreSQL y Blob (flujos 4 y 5).
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = var.vm.os_disk_name
    caching              = "ReadWrite"
    storage_account_type = var.vm.os_disk_type
    disk_size_gb         = var.vm.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.vm.image.publisher
    offer     = var.vm.image.offer
    sku       = var.vm.image.sku
    version   = var.vm.image.version
  }

  # Diagnóstico de arranque con almacenamiento administrado por Azure.
  boot_diagnostics {}

  tags = local.tags
}

module "resource_group" {
  source                  = "../modules/azurerm_resource_group"
  resource_group_name     = "todoapp-rg-jeet"
  resource_group_location = "centralindia"
}

module "vnet" {
  depends_on              = [module.resource_group]
  source                  = "../modules/azurerm_virtual_network"
  azurerm_virtual_network = "todoapp-vnet-jeet"
  resource_group_location = "centralindia"
  resource_group_name     = "todoapp-rg-jeet"
  address_space           = ["10.0.0.0/16"]
}

module "frontend_subnet" {
  depends_on           = [module.vnet]
  source               = "../modules/azurerm_subnet"
  subnet_name          = "frontend-subnet-jeet"
  resource_group_name  = "todoapp-rg-jeet"
  virtual_network_name = "todoapp-vnet-jeet"
  address_prefixes     = ["10.0.1.0/24"]
}

module "backend_subnet" {
  depends_on           = [module.vnet]
  source               = "../modules/azurerm_subnet"
  subnet_name          = "backend-subnet-jeet"
  resource_group_name  = "todoapp-rg-jeet"
  virtual_network_name = "todoapp-vnet-jeet"
  address_prefixes     = ["10.0.2.0/24"]
}

module "public_ip_name" {
  depends_on              = [module.resource_group]
  source                  = "../modules/azurerm_public_ip"
  public_ip_name          = "todoapp-public-ip-jeet"
  resource_group_name     = "todoapp-rg-jeet"
  resource_group_location = "centralindia"
  allocation_method       = "Static"
}

module "frontend_vm" {
  depends_on              = [module.frontend_subnet, module.public_ip_name, module.key_vault]
  source                  = "../modules/azurerm_virtual_machine"
  vm_name                 = "todoapp-vm-jeet"
  resource_group_name     = "todoapp-rg-jeet"
  resource_group_location = "centralindia"
  vm_size                 = "Standard_B1s"
  os_publisher            = "Canonical"
  os_offer                = "0001-com-ubuntu-server-jammy"
  os_sku                  = "22_04-lts"
  os_version              = "latest"
  network_nic_name        = "frontend-nic"
  frontend_subnet_name    = "frontend-subnet-jeet"
  virtual_network_name    = "todoapp-vnet-jeet"
  public_ip_address_name = "todoapp-public-ip-jeet"
  key_vault_name = "myKeyvault2400"
  secretname = {
    vm_username = {
      name  = "vm-username"
      value = "username"
    }
    vm_password = {
      name  = "vm-password"
      value = "P@ssw0rd1234!"
    }
  }
}

# resource "null_resource" "install_nginx" {
#   depends_on = [module.frontend_vm]

#   # This ensures it runs again if the IP changes
#   triggers = {
#     vm_public_ip = module.public_ip_name.public_ip_address
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo Installing NGINX...",
#       "sudo apt-get update -y",
#       "sudo apt-get install nginx -y",
#       "sudo systemctl enable nginx",
#       "sudo systemctl start nginx"
#     ]

#     connection {
#       type     = "ssh"
#       user     = "azureuser"
#       password = "P@ssw0rd1234!"
#       host     = module.public_ip_name.public_ip_address
#       timeout  = "5m"
#     }
#   }
# }

module "backend_public_ip_name" {
  depends_on              = [module.resource_group]
  source                  = "../modules/azurerm_public_ip"
  public_ip_name          = "todoapp-backend-public-ip-jeet"
  resource_group_name     = "todoapp-rg-jeet"
  resource_group_location = "centralindia"
  allocation_method       = "Static"
}

module "backend_vm" {
  depends_on              = [module.backend_subnet,module.backend_public_ip_name, module.key_vault]
  source                  = "../modules/azurerm_virtual_machine"
  vm_name                 = "todoapp-backend-vm-jeet"
  resource_group_name     = "todoapp-rg-jeet"
  resource_group_location = "centralindia"
  vm_size                 = "Standard_B1s"
  os_publisher            = "Canonical"
  os_offer                = "0001-com-ubuntu-server-jammy"
  os_sku                  = "22_04-lts"
  os_version              = "latest"
  network_nic_name        = "backend-nic"
  frontend_subnet_name    = "backend-subnet-jeet"
  virtual_network_name    = "todoapp-vnet-jeet"
  public_ip_address_name = "todoapp-backend-public-ip-jeet"
  key_vault_name = "myKeyvault2400"
  secretname = {
    vm_username = {
      name  = "vm-username"
      value = "username"
    }
    vm_password = {
      name  = "vm-password"
      value = "P@ssw0rd1234!"
    }
  } 
}

module "sql_server" {
  depends_on                   = [module.backend_vm,module.key_vault]
  source                       = "../modules/azurerm_sql_server"
  sql_server_name              = "todoapp-sql-server-jeet"
  resource_group_name          = "todoapp-rg-jeet"
  resource_group_location      = "centralindia"
  sql_server_version           = "12.0"
  key_vault_name            = "myKeyvault2400"
  secretname = {
    vm_username = {
      name  = "vm-username"
      value = "username"
    }
    vm_password = {
      name  = "vm-password"
      value = "P@ssw0rd1234!"
    }
  } 
}

module "sql_database" {
  depends_on    = [module.sql_server,module.key_vault]
  source        = "../modules/azurerm_sql_database"
  database_name = "todoappdb-jeet"
  collation     = "SQL_Latin1_General_CP1_CI_AS"
  license_type  = "LicenseIncluded"
  max_size_gb   = 2
  sku_name      = "GP_S_Gen5_2"
  sql_server_name = "todoapp-sql-server-jeet"
  resource_group_name = "todoapp-rg-jeet"
}

module "key_vault" {
  depends_on              = [module.resource_group]
  source                  = "../modules/azure_key_vault"
  key_vault_name          = "myKeyvault2400"
  resource_group_name     = "todoapp-rg-jeet"
  resource_group_location = "centralindia"
  tenant_id               = "ec303232-515f-4ef2-a3d5-df83712a9eb0"
  soft_delete_retention_days = 7
  key_vault_secrets = {
    vm_password = {
      name  = "vm-password"
      value = "password@123"
    },
    vm_username = {
      name  = "vm-username"
      value = "username"
    },
    db_username = {
      name  = "db-username"
      value = "dbusername"
    },
    db_password = {
      name  = "db-password"
      value = "dbpass"
    }
  }
}


#tester

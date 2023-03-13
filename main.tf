terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.47.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "k8" {
  name     = "k8-resources"
  location = "West Europe"
}


resource "azurerm_public_ip" "k8" {
  count               = 2
  name                = "linux-${count.index}-static-ip"
  location            = azurerm_resource_group.k8.location
  resource_group_name = azurerm_resource_group.k8.name
  allocation_method   = "Static"
  depends_on = [
    azurerm_resource_group.k8
  ]
}

resource "azurerm_network_security_group" "k8a" {
  name                = "k8-master-nsg"
  location            = azurerm_resource_group.k8.location
  resource_group_name = azurerm_resource_group.k8.name

  security_rule {
    name                       = "kubernetes-api-server"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "etcd-server-client-API"
    description                = "allow-http"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Kubelet-api"
    description                = "allow-http"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "kube-scheduler"
    description                = "allow-http"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10259"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "kube-controller-manager"
    description                = "allow-http"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10257"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ssh"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "htp"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "https"
    priority                   = 190
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "k8b" {
  name                = "k8-worker-nsg"
  location            = azurerm_resource_group.k8.location
  resource_group_name = azurerm_resource_group.k8.name

  security_rule {
    name                       = "kubelet-api"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "nodeport-service"
    description                = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ssh"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}



resource "azurerm_subnet_network_security_group_association" "k8a" {
  subnet_id                 = azurerm_subnet.k8[0].id
  network_security_group_id = azurerm_network_security_group.k8a.id
}
resource "azurerm_subnet_network_security_group_association" "k8b" {
  subnet_id                 = azurerm_subnet.k8[1].id
  network_security_group_id = azurerm_network_security_group.k8b.id
}

resource "azurerm_virtual_network" "k8" {
  name                = "k8-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.k8.location
  resource_group_name = azurerm_resource_group.k8.name
}

resource "azurerm_subnet" "k8" {
  count                = 2
  name                 = "k8-sunbet${count.index}"
  resource_group_name  = azurerm_resource_group.k8.name
  virtual_network_name = azurerm_virtual_network.k8.name
  address_prefixes     = ["10.0.${count.index + 1}.0/24"]
}

resource "azurerm_network_interface" "k8a" {
  name                = "k8-master-nic"
  location            = azurerm_resource_group.k8.location
  resource_group_name = azurerm_resource_group.k8.name


  ip_configuration {
    name                          = "master"
    subnet_id                     = azurerm_subnet.k8[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.k8[0].id
  }
}
resource "azurerm_network_interface" "k8b" {
  name                = "k8-worker-nic"
  location            = azurerm_resource_group.k8.location
  resource_group_name = azurerm_resource_group.k8.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8[1].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.k8[1].id
  }
}

resource "azurerm_linux_virtual_machine" "k8a" {
  name                  = "controlplane"
  resource_group_name   = azurerm_resource_group.k8.name
  location              = azurerm_resource_group.k8.location
  size                  = "Standard_F2"
  admin_username        = "kroo"
  network_interface_ids = [azurerm_network_interface.k8a.id, ]
  custom_data           = base64encode(data.template_file.master-node-cloud-init.rendered)


  admin_ssh_key {
    username   = "kroo"
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
}
data "template_file" "master-node-cloud-init" {
  template = file("master-node-user-data.sh")
}

data "template_file" "worker-node-cloud-init" {
  template = file("worker-node-user-data.sh")
}

resource "azurerm_linux_virtual_machine" "k8b" {
    count = 1
  name                  = "worker-node-${count.index +1}"
  resource_group_name   = azurerm_resource_group.k8.name
  location              = azurerm_resource_group.k8.location
  size                  = "Standard_F2"
  admin_username        = "kroo"
  network_interface_ids = [azurerm_network_interface.k8b.id, ]
  custom_data           = base64encode(data.template_file.worker-node-cloud-init.rendered)

  admin_ssh_key {
    username   = "kroo"
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
  depends_on = [
    azurerm_linux_virtual_machine.k8a
  ]
}

output "master-node-ip" {
    value = azurerm_public_ip.k8[0].ip_address
  
}

output "worker-node-ip" {
    value = azurerm_public_ip.k8[1].ip_address
  
}
# ssh -i ~/.ssh/id_rsa kroo@13.80.41.40
# ssh -i ~/.ssh/id_rsa kroo@13.80.43.81


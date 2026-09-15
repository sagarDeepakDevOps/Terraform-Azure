terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Reserve a predictable public source address for outbound workload traffic.
# Creation: Azure allocates a static Standard IPv4 resource in the gateway's region;
# its ID is attached to the NAT gateway below, rather than directly to VM NICs.
# Important: The address is known after deployment and remains allocated/billable
# until deleted. It is an egress address, not an inbound SSH or web listener.
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Purpose: Provide managed source NAT for subnets whose implicit egress is disabled.
# Creation: AzureRM provisions a Standard NAT gateway with a ten-minute idle timeout.
# Public-IP and subnet bindings below complete the network setup; the gateway alone
# is not attached to workloads and does not yet provide their outbound connectivity.
# Important: NAT has fixed and usage charges and does not filter destinations like
# a firewall. NSGs and routes still determine which connections can reach it.
resource "azurerm_nat_gateway" "this" {
  name                    = var.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

# Purpose: Give the NAT gateway the public address it will use for source translation.
# Creation: Reference the new NAT gateway and Standard public IP IDs, so Terraform
# waits for both Azure resources before creating their association.
# Important: Workloads also need the subnet associations below. When boot scripts
# download packages, the caller should wait for the whole NAT module to complete.
resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}

# Purpose: Enable explicit NAT egress on each selected workload subnet.
# Creation: for_each creates one subnet-to-gateway association per stable map key.
# Azure then translates eligible outbound Internet connections from those subnets
# through this gateway; it does not require a public IP on each workload NIC.
# Important: A subnet can use only one NAT gateway. NAT does not open unsolicited
# inbound access and does not override a UDR that sends traffic to a firewall.
resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each       = var.subnet_ids
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this.id
}
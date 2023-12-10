# Define the public subnet cidr values
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.0.0/26", "10.0.0.64/26"]
}

# Define the private subnet cidr values
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.0.128/26", "10.0.0.192/26"]

}

# Define the Availability zones
variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["eu-north-1a", "eu-north-1b"]
}
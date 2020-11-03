variable "prefix" {
  description = "The prefix for all resources"
  default = "webserver"
}

variable "location" {
  description = "The Azure Region in which all resources are created."
  default = "UK South"
}

variable "user" {
  description = "User login name for the VMs."
  default = "i%Zm2Fb9XkVdS0@Wrk5!"
}

variable "password" {
  description = "Password for the VMs"
  default = "6tXxV!QUM%087!3OKrg2"
}

variable "numofservers" {
  description = "Number of VMs to be created in the load balancer backendpool"
  default = 3
}

variable "project" {
  description = "Name of the project, used to tag resources"
  default = "Deploy web server in Azure"
}

variable "role_name" {
  description = "The name of the IAM role"
  type        = string
}

variable "service_name" {
  description = "The name of the service to allow assume role"
  type        = string
}

variable "policy_name" {
  description = "The name of the IAM policy"
  type        = string
}

variable "actions" {
  description = "The actions to allow in the policy"
  type        = list(string)
}

variable "resources" {
  description = "The resources to which the actions apply in the policy"
  type        = list(string)
}





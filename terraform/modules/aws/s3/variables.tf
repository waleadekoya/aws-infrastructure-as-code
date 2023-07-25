variable "bucket" {
  description = "The name of the bucket."
  type        = string
}

variable "acl" {
  description = "The access control list setting."
  type        = string
  default     = "private"
}

variable "tags" {
  description = "The tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

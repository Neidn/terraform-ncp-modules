# 타입 검증은 스택(stacks/web-service/variables.tf)에서 한다. 여기서는 전달만.
variable "name_prefix" { type = string }
variable "vpc_no" { type = string }
variable "login_key_name" {
  type    = string
  default = null
}

variable "existing_subnets" {
  type    = any
  default = {}
}
variable "existing_acgs" {
  type    = any
  default = {}
}
variable "existing_servers" {
  type    = any
  default = {}
}
variable "subnets" {
  type    = any
  default = {}
}
variable "acgs" {
  type    = any
  default = {}
}
variable "server_groups" {
  type    = any
  default = {}
}
variable "load_balancers" {
  type    = any
  default = {}
}
variable "database" {
  type    = any
  default = null
}

variable "database_password" {
  description = "export TF_VAR_database_password=..."
  type        = string
  default     = null
  sensitive   = true
}

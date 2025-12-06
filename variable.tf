variable "db_password" {
  description = "Wachtwoord voor de RDS database"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

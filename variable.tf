variable "db_password" {
  description = "Wachtwoord voor de RDS database"
  type        = string
  sensitive   = true
}

variable "hr_password" {
  description = "Wachtwoord voor de hr gebruiker in de database"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

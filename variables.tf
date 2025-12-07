variable "db_password" {
  description = "Database admin wachtwoord"
  type        = string
  sensitive   = true
}

variable "hr_password" {
  description = "HR admin wachtwoord voor login"
  type        = string
  sensitive   = true
}
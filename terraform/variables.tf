variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "admin12345"
}

variable "db_name" {
  default = "logdb"
}

variable "key_name" {
  description = "EC2 key pair name"
  default     = "aws-key"  # 🔁 Replace with actual key pair name
}

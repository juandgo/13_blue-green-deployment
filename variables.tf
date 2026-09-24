variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be deployed"
}

variable "prefix" {
  type        = string
  description = "Prefix for naming resources in compliance with lab naming conventions"
}

variable "blue_weight" {
  type        = number
  description = "Weight percentage of traffic routed to the Blue target group"
}

variable "green_weight" {
  type        = number
  description = "Weight percentage of traffic routed to the Green target group"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for ASG instances"
}
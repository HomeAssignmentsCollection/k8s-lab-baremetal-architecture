# TFLint Configuration
# This file configures tflint rules for the project

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "azurerm" {
  enabled = true
  version = "0.25.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "google" {
  enabled = true
  version = "0.25.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# Global settings
config {
  module = true
  force  = false
}

# Rules configuration
rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

# AWS specific rules
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_invalid_ami" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_instance_invalid_key_name" {
  enabled = true
}

rule "aws_instance_invalid_iam_profile" {
  enabled = true
}

rule "aws_instance_invalid_vpc_security_group" {
  enabled = true
}

rule "aws_instance_invalid_subnet" {
  enabled = true
}

rule "aws_instance_invalid_availability_zone" {
  enabled = true
}

# Azure specific rules
rule "azurerm_resource_missing_tags" {
  enabled = true
  tags = [
    "Environment",
    "Project",
    "Owner"
  ]
}

rule "azurerm_virtual_network_invalid_name" {
  enabled = true
}

rule "azurerm_subnet_invalid_name" {
  enabled = true
}

# Google specific rules
rule "google_compute_instance_invalid_machine_type" {
  enabled = true
}

rule "google_compute_instance_invalid_zone" {
  enabled = true
}

# Disable some rules that are too strict for this project
rule "terraform_deprecated_interpolation" {
  enabled = false
}

rule "terraform_deprecated_interpolation_syntax" {
  enabled = false
}

# Custom rules can be added here
# rule "custom_rule" {
#   enabled = true
#   custom_parameter = "value"
# } 
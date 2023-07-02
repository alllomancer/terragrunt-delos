terraform {
  source = "."
}


include "root" {
  path = find_in_parent_folders("root.hcl")
}


include "provider" {
  path = find_in_parent_folders("provider.hcl")
}

dependency "vpc" {
  config_path  = "../../infra/vpc"
  skip_outputs = true
}


dependency "sg" {
  config_path  = "../../infra/sg"
  skip_outputs = true
}

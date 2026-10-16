location             = "mexicocentral"
resource_group_name  = "rg-utvt-tfstate-dev-mxc-001"
storage_account_name = "sttfutvtintdevmxc001"
container_name       = "tfstate"

tags = {
  environment = "dev"
  project     = "integradora"
  cost_center = "utvt"
  owner       = "equipo-integradora"
  managed_by  = "terraform"
  repository  = "github.com/MiguelM07w/terraform_4"
}

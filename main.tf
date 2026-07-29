# -----------------------------------------------------------------------------
# main.tf
# Data sources e valores locais compartilhados entre os demais arquivos .tf
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = coalesce(var.aws_account_id, data.aws_caller_identity.current.account_id)

  common_tags = {
    Project = "athena-glue-workshop"
    Speaker = "Gustavo Tavares"
  }

  raw_bucket_name            = "${var.workshop_prefix}-raw-${local.account_id}"
  processed_bucket_name      = "${var.workshop_prefix}-processed-${local.account_id}"
  athena_results_bucket_name = "${var.workshop_prefix}-athena-results-${local.account_id}"
  glue_scripts_bucket_name   = "${var.workshop_prefix}-glue-scripts-${local.account_id}"

  glue_database_name    = "workshop_db"
  raw_crawler_name       = "${var.workshop_prefix}-raw-crawler"
  etl_job_name            = "${var.workshop_prefix}-etl-job"
  athena_workgroup_name   = "${var.workshop_prefix}-workgroup"
  processed_table_name    = "vendas_processed"
}

# -----------------------------------------------------------------------------
# glue.tf
# Glue Data Catalog (Database), Crawler para descoberta dos dados raw e
# ETL Job para transformacao CSV -> Parquet.
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Glue_Database
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "workshop_db" {
  name        = local.glue_database_name
  description = "Data Catalog do workshop 'Analise de Dados sem complicacao com AWS Athena e Glue'."
}

# ---------------------------------------------------------------------------
# Glue_Crawler
# ---------------------------------------------------------------------------
resource "aws_glue_crawler" "raw_crawler" {
  name          = local.raw_crawler_name
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.workshop_db.name
  schedule      = null # execucao on-demand durante a demonstracao ao vivo

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/vendas/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy.glue_role_policy,
    aws_s3_object.sample_dataset,
  ]
}

# ---------------------------------------------------------------------------
# Glue_ETL_Job
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "glue_job_output" {
  name              = "/aws-glue/jobs/output"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "glue_job_error" {
  name              = "/aws-glue/jobs/error"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_glue_job" "etl_job" {
  name              = local.etl_job_name
  role_arn          = aws_iam_role.glue_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 15 # minutos - adequado para demonstracao ao vivo com dataset pequeno

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/etl_job.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                    = "python"
    "--raw_s3_path"                     = "s3://${aws_s3_bucket.raw.bucket}/vendas/"
    "--processed_s3_path"               = "s3://${aws_s3_bucket.processed.bucket}/vendas/"
    "--glue_database"                   = aws_glue_catalog_database.workshop_db.name
    "--processed_table_name"            = local.processed_table_name
    "--enable-metrics"                  = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-glue-datacatalog"         = "true"
    "--TempDir"                         = "s3://${aws_s3_bucket.glue_scripts.bucket}/tmp/"
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy.glue_role_policy,
    aws_s3_object.etl_script,
    aws_cloudwatch_log_group.glue_job_output,
    aws_cloudwatch_log_group.glue_job_error,
  ]
}

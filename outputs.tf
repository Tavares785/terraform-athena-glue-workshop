# -----------------------------------------------------------------------------
# outputs.tf
# -----------------------------------------------------------------------------

# --- S3 buckets ---
output "s3_raw_bucket_name" {
  description = "Nome do S3_Raw_Bucket."
  value       = aws_s3_bucket.raw.bucket
}

output "s3_raw_bucket_arn" {
  description = "ARN do S3_Raw_Bucket."
  value       = aws_s3_bucket.raw.arn
}

output "s3_processed_bucket_name" {
  description = "Nome do S3_Processed_Bucket."
  value       = aws_s3_bucket.processed.bucket
}

output "s3_processed_bucket_arn" {
  description = "ARN do S3_Processed_Bucket."
  value       = aws_s3_bucket.processed.arn
}

output "s3_athena_results_bucket_name" {
  description = "Nome do S3_Athena_Results_Bucket."
  value       = aws_s3_bucket.athena_results.bucket
}

output "s3_athena_results_bucket_arn" {
  description = "ARN do S3_Athena_Results_Bucket."
  value       = aws_s3_bucket.athena_results.arn
}

output "glue_script_bucket_name" {
  description = "Nome do Glue_Script_Bucket."
  value       = aws_s3_bucket.glue_scripts.bucket
}

output "glue_script_bucket_arn" {
  description = "ARN do Glue_Script_Bucket."
  value       = aws_s3_bucket.glue_scripts.arn
}

# --- Glue ---
output "glue_database_name" {
  description = "Nome do Glue_Database no Data Catalog."
  value       = aws_glue_catalog_database.workshop_db.name
}

output "glue_crawler_name" {
  description = "Nome do Glue_Crawler."
  value       = aws_glue_crawler.raw_crawler.name
}

output "glue_etl_job_name" {
  description = "Nome do Glue_ETL_Job."
  value       = aws_glue_job.etl_job.name
}

# --- Athena ---
output "athena_workgroup_name" {
  description = "Nome do Athena_Workgroup."
  value       = aws_athena_workgroup.workshop.name
}

output "athena_workgroup_arn" {
  description = "ARN do Athena_Workgroup."
  value       = aws_athena_workgroup.workshop.arn
}

# --- IAM (uteis para depuracao durante a palestra) ---
output "iam_glue_role_arn" {
  description = "ARN da IAM_Glue_Role."
  value       = aws_iam_role.glue_role.arn
}

output "iam_athena_role_arn" {
  description = "ARN da IAM_Athena_Role."
  value       = aws_iam_role.athena_role.arn
}

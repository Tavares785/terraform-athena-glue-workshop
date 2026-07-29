# -----------------------------------------------------------------------------
# s3.tf
# Buckets S3 do pipeline: raw, processed, athena-results e glue-scripts.
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# S3_Raw_Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "raw" {
  bucket = local.raw_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket = aws_s3_bucket.raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# S3_Processed_Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "processed" {
  bucket = local.processed_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket = aws_s3_bucket.processed.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# S3_Athena_Results_Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "athena_results" {
  bucket = local.athena_results_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Glue_Script_Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "glue_scripts" {
  bucket = local.glue_scripts_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Sample_Dataset - upload do CSV de vendas ficticias no S3_Raw_Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_object" "sample_dataset" {
  bucket       = aws_s3_bucket.raw.id
  key          = "vendas/ano=2024/vendas_sample.csv"
  source       = "${path.module}/data/vendas_sample.csv"
  etag         = filemd5("${path.module}/data/vendas_sample.csv")
  content_type = "text/csv"

  tags = local.common_tags

  depends_on = [aws_s3_bucket_public_access_block.raw]
}

# ---------------------------------------------------------------------------
# Script Python do Glue_ETL_Job
# ---------------------------------------------------------------------------
resource "aws_s3_object" "etl_script" {
  bucket       = aws_s3_bucket.glue_scripts.id
  key          = "scripts/etl_job.py"
  source       = "${path.module}/scripts/etl_job.py"
  etag         = filemd5("${path.module}/scripts/etl_job.py")
  content_type = "text/x-python"

  tags = local.common_tags

  depends_on = [aws_s3_bucket_public_access_block.glue_scripts]
}

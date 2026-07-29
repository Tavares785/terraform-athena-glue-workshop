# -----------------------------------------------------------------------------
# athena.tf
# Athena_Workgroup dedicado ao workshop, com resultados isolados em S3,
# engine v3 e limite de bytes escaneados por query.
# -----------------------------------------------------------------------------

resource "aws_athena_workgroup" "workshop" {
  name  = local.athena_workgroup_name
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = 1073741824 # 1 GiB

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  tags = local.common_tags

  depends_on = [aws_s3_bucket_public_access_block.athena_results]
}

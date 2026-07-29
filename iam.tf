# -----------------------------------------------------------------------------
# iam.tf
# IAM_Glue_Role e IAM_Athena_Role com privilegio minimo (least privilege).
# Nenhuma policy gerenciada de amplo escopo (AdministratorAccess,
# AmazonS3FullAccess) e utilizada; todos os recursos das inline policies
# sao ARNs especificos.
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# IAM_Glue_Role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_role" {
  name               = "${var.workshop_prefix}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "glue_role_policy" {
  # Leitura do S3_Raw_Bucket e do Glue_Script_Bucket
  statement {
    sid     = "ListRawAndScriptBuckets"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.raw.arn,
      aws_s3_bucket.glue_scripts.arn,
    ]
  }

  statement {
    sid     = "ReadRawAndScriptObjects"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.raw.arn}/*",
      "${aws_s3_bucket.glue_scripts.arn}/*",
    ]
  }

  # Escrita no S3_Processed_Bucket
  statement {
    sid       = "WriteProcessedBucket"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.processed.arn}/*"]
  }

  statement {
    sid       = "ListProcessedBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.processed.arn]
  }

  # Glue Data Catalog
  statement {
    sid    = "GlueDataCatalogAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:BatchCreatePartition",
      "glue:BatchGetPartition",
      "glue:GetPartition",
      "glue:GetPartitions",
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${local.account_id}:catalog",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:database/${local.glue_database_name}",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:table/${local.glue_database_name}/*",
    ]
  }

  # CloudWatch Logs
  statement {
    sid    = "GlueCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      # Logs do Glue_ETL_Job
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws-glue/jobs/*",
      # Logs do Glue_Crawler (log group padrao usado pelo AWS Glue para crawlers)
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws-glue/crawlers",
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws-glue/crawlers:*",
    ]
  }
}

resource "aws_iam_role_policy" "glue_role_policy" {
  name   = "${var.workshop_prefix}-glue-role-policy"
  role   = aws_iam_role.glue_role.id
  policy = data.aws_iam_policy_document.glue_role_policy.json
}

# ---------------------------------------------------------------------------
# IAM_Athena_Role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "athena_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["athena.amazonaws.com", "glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "athena_role" {
  name               = "${var.workshop_prefix}-athena-role"
  assume_role_policy = data.aws_iam_policy_document.athena_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "athena_role_policy" {
  # Leitura do S3_Processed_Bucket e do S3_Raw_Bucket para execucao de queries
  statement {
    sid     = "ListProcessedAndRawBuckets"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.processed.arn,
      aws_s3_bucket.raw.arn,
    ]
  }

  statement {
    sid     = "ReadProcessedAndRawObjects"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.processed.arn}/*",
      "${aws_s3_bucket.raw.arn}/*",
    ]
  }

  # Escrita dos resultados de query no S3_Athena_Results_Bucket
  statement {
    sid       = "WriteAthenaResults"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.athena_results.arn}/*"]
  }

  statement {
    sid       = "ListAthenaResultsBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.athena_results.arn]
  }

  # Leitura no Glue Data Catalog
  statement {
    sid    = "GlueDataCatalogReadOnly"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${local.account_id}:catalog",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:database/${local.glue_database_name}",
      "arn:aws:glue:${var.aws_region}:${local.account_id}:table/${local.glue_database_name}/*",
    ]
  }
}

resource "aws_iam_role_policy" "athena_role_policy" {
  name   = "${var.workshop_prefix}-athena-role-policy"
  role   = aws_iam_role.athena_role.id
  policy = data.aws_iam_policy_document.athena_role_policy.json
}
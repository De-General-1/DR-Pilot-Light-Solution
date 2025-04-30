provider "aws" {
  alias  = "primary"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "failover"
  region = "us-east-1"
}

# Source bucket (primary region)
resource "aws_s3_bucket" "source" {
  provider = aws.primary
  bucket   = var.primary_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source_versioning" {
  provider = aws.primary
  bucket   = aws_s3_bucket.source.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replica bucket (failover region)
resource "aws_s3_bucket" "replica" {
  provider = aws.failover
  bucket   = var.dr_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "replica_versioning" {
  provider = aws.failover
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}



resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.primary
  depends_on = [aws_s3_bucket_versioning.source_versioning, aws_s3_bucket_versioning.replica_versioning]

  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Disabled"
    }


    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}

# Allow public * access to source bucket via bucket policy
resource "aws_s3_bucket_policy" "public_crud" {
  provider = aws.primary
  bucket   = aws_s3_bucket.source.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [
          "${aws_s3_bucket.source.arn}",
          "${aws_s3_bucket.source.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "source_block" {
  provider = aws.primary
  bucket   = aws_s3_bucket.source.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# IAM role for replication
resource "aws_iam_role" "replication_role" {
  provider = aws.primary
  name     = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  provider = aws.primary
  name     = "s3-replication-policy"
  role     = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.source.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention",
          "s3:GetObjectTagging",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.source.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*",
        ]
        Resource = "${aws_s3_bucket.replica.arn}/*"
      }
    ]
  })
}
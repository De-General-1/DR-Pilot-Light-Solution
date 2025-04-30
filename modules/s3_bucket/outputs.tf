output "primary_bucket_name" {
   value = aws_s3_bucket.source.bucket
}

output "dr_bucket_name" {
  value = aws_s3_bucket.replica.bucket
}

output "kms_key_arn" {
  value = aws_kms_key.kms_key.arn
}

output "kms_key_id" {
  value = aws_kms_key.kms_key.key_id
}

output "bucket_id" {
  value = aws_s3_bucket.bucket.id
}

# output "log_bucket_id" {
#     # value = aws_s3_bucket.log_bucket.id
# }

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

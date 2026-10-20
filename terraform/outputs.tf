output "bucket_name" {
  description = "Sync target for the deploy pipeline."
  value       = aws_s3_bucket.site.id
}

# TODO: uncomment once TODO 2 and TODO 3 in main.tf exist.
# The deploy workflow needs distribution_id for the cache invalidation.
#
# output "distribution_id" {
#   description = "Needed for: aws cloudfront create-invalidation --distribution-id"
#   value       = aws_cloudfront_distribution.site.id
# }
#
# output "distribution_domain" {
#   description = "The *.cloudfront.net hostname — useful for testing before DNS cuts over."
#   value       = aws_cloudfront_distribution.site.domain_name
# }
#
# output "site_url" {
#   value = "https://${var.domain_name}"
# }

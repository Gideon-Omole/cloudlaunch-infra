output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "iam_user" {
  value = aws_iam_user.cloudlaunch_user.name
}

# Output the user's initial password (only visible after apply)
output "cloudlaunch_user_password" {
  value     = aws_iam_user_login_profile.cloudlaunch_user.password
  sensitive = true
}


output "vpc_id" {
  value = aws_vpc.cloudlaunch.id
}

output "cloudlaunch_cloudfront_url" {
  value = aws_cloudfront_distribution.cloudlaunch_site_cdn.domain_name
}


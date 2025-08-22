#create an iam user called cloudlaunch-user

resource "aws_iam_user" "cloudlaunch_user" {
  name = "cloudlaunch-user"
  force_destroy = true
}


#gives the user console access with a random password generated
resource "aws_iam_user_login_profile" "cloudlaunch_user" {
  user    = aws_iam_user.cloudlaunch_user.name
  password_reset_required = true
}

#define the IAM policy for the user

resource "aws_iam_policy" "cloudlaunch_policy" {
  name        = "cloudlaunch-policy"
  description = "Custom policy for CloudLaunch user"
  policy      = file("${path.module}/policies/cloudlaunch-user-policy.json")
}

#attach the policy to the user

resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = aws_iam_user.cloudlaunch_user.name
  policy_arn = aws_iam_policy.cloudlaunch_policy.arn
}

# IAM policy for read-only access to VPC and its components
resource "aws_iam_policy" "cloudlaunch_vpc_readonly_policy" {
  name        = "cloudlaunch-vpc-readonly-policy"
  description = "Read-only access to VPC and its components for cloudlaunch-user"
  policy      = file("${path.module}/policies/cloudlaunch-vpc-readonly-policy.json")
}

# Attach to user
resource "aws_iam_user_policy_attachment" "attach_vpc_readonly" {
  user       = aws_iam_user.cloudlaunch_user.name
  policy_arn = aws_iam_policy.cloudlaunch_vpc_readonly_policy.arn
}








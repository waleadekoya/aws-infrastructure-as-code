#resource "aws_iam_role" "ec2_role" {
#  name               = "ec2_role"
#  assume_role_policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": "sts:AssumeRole",
#      "Principal": {
#        "Service": "ec2.amazonaws.com"
#      },
#      "Effect": "Allow",
#      "Sid": ""
#    }
#  ]
#}
#EOF
#}
#
#resource "aws_iam_role" "lambda_role" {
#  name               = "lambda_role"
#  assume_role_policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": "sts:AssumeRole",
#      "Principal": {
#        "Service": "lambda.amazonaws.com"
#      },
#      "Effect": "Allow",
#      "Sid": ""
#    }
#  ]
#}
#EOF
#}
#
#resource "aws_iam_instance_profile" "ec2_profile" {
#  name = "ec2_profile"
#  role = aws_iam_role.ec2_role.name
#}
#
#
#resource "aws_iam_role_policy" "s3_full_access" {
#  name   = "s3_full_access"
#  role   = aws_iam_role.ec2_role.id
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Action": "s3:*",
#      "Resource": "*"
#    }
#  ]
#}
#EOF
#}

resource "aws_iam_role" "role" {
  name               = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = var.service_name
        },
        Effect = "Allow",
      },
    ]
  })
}

resource "aws_iam_policy" "policy" {
  name   = var.policy_name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = var.actions,
        Resource = var.resources
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}


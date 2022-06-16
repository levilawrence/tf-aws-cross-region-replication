output "policy_arn" {
  value = aws_iam_policy.replication.arn
}

output "roles" {
  value = aws_iam_role.replication.arn
}

output "replication_role" {
  value = aws_iam_role.replication.name
}

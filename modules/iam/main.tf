# ------------------------------------------------------------------------------
# iam role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "replication" {
  name_prefix = var.name_prefix

  assume_role_policy = "${var.assume_role_policy}"
}

resource "aws_iam_policy" "replication" {
  name_prefix = var.name_prefix
  description = var.description

  policy = "${var.policy}"
}

resource "aws_iam_policy_attachment" "replication" {
  name       = var.name
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}

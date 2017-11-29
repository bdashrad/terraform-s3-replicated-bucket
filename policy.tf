data "aws_iam_policy_document" "replication_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  name               = "s3-replication-${var.bucket}"
  assume_role_policy = "${data.aws_iam_policy_document.replication_role.json}"
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket}-replica/*",
    ]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = "s3-replication-${var.bucket}"
  role   = "${aws_iam_role.replication.id}"
  policy = "${data.aws_iam_policy_document.replication.json}"
}

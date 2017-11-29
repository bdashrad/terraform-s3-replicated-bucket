variable "bucket" {
  type        = "string"
  description = "Name of the S3 bucket to create"
}

variable "log_bucket" {
  type        = "string"
  description = "Name of bucket to use for logging"
}

variable "region" {
  type        = "string"
  description = "Region to create bucket in"
  default     = "us-east-1"
}

variable "replica_log_bucket" {
  type        = "string"
  description = "Name of bucket to use for replica logging"
}

variable "replica_region" {
  type        = "string"
  description = "Region to create replica bucket in"
  default     = "us-west-2"
}

provider "aws" {
  version = "~> 1.2"
  alias   = "source"
  region  = "${var.region}"
}

provider "aws" {
  version = "~> 1.2"
  alias   = "destination"
  region  = "${var.replica_region}"
}

module "role" {
  source = "../s3_replica_policy"
  bucket = "${var.bucket}"
}

resource "aws_s3_bucket" "replica" {
  provider = "aws.destination"
  bucket   = "${var.bucket}-replica"
  region   = "${var.replica_region}"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${var.replica_log_bucket}"
    target_prefix = "${var.bucket}-replica/"
  }

  tags {
    Name        = "${var.bucket}-replica"
    terraform   = "true"
  }
}

resource "aws_s3_bucket" "source" {
  provider = "aws.source"
  bucket   = "${var.bucket}"
  region   = "${var.region}"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${var.log_bucket}"
    target_prefix = "${var.bucket}/"
  }

  replication_configuration {
    role = "${aws_iam_role.replication.arn}"

    rules {
      prefix = ""
      status = "Enabled"
      id     = "${var.bucket}-replication"

      destination {
        bucket = "${aws_s3_bucket.replica.arn}"
      }
    }
  }

  tags {
    Name        = "${var.bucket}"
    terraform   = "true"
  }

  depends_on = [
    "aws_s3_bucket.replica",
  ]
}

output "id" {
  value = "${aws_s3_bucket.source.id}"
}

output "arn" {
  value = "${aws_s3_bucket.source.arn}"
}

output "replica_id" {
  value = "${aws_s3_bucket.replica.id}"
}

output "replica_arn" {
  value = "${aws_s3_bucket.replica.arn}"
}

# S3 Cross-Region Replication (CRR) Setup Guide

## Overview

This guide describes how to set up S3 Cross-Region Replication from `ap-northeast-1` (Tokyo) to `ap-northeast-3` (Osaka) for both Active Storage and backup buckets.

## Buckets to Replicate

| Source Bucket (ap-northeast-1) | Destination Bucket (ap-northeast-3) | Purpose |
|-------------------------------|-------------------------------------|---------|
| `{S3_BUCKET_NAME}` | `{S3_BUCKET_NAME}-replica` | Active Storage files |
| `{BACKUP_S3_BUCKET}` | `{BACKUP_S3_BUCKET}-replica` | Database backups |

## Prerequisites

- AWS CLI configured with appropriate permissions
- S3 buckets must have versioning enabled on both source and destination

## Step 1: Enable Versioning

```bash
# Source buckets (Tokyo)
aws s3api put-bucket-versioning \
  --bucket ${S3_BUCKET_NAME} \
  --versioning-configuration Status=Enabled \
  --region ap-northeast-1

aws s3api put-bucket-versioning \
  --bucket ${BACKUP_S3_BUCKET} \
  --versioning-configuration Status=Enabled \
  --region ap-northeast-1

# Destination buckets (Osaka)
aws s3api put-bucket-versioning \
  --bucket ${S3_BUCKET_NAME}-replica \
  --versioning-configuration Status=Enabled \
  --region ap-northeast-3

aws s3api put-bucket-versioning \
  --bucket ${BACKUP_S3_BUCKET}-replica \
  --versioning-configuration Status=Enabled \
  --region ap-northeast-3
```

## Step 2: Create IAM Role for Replication

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Save as `trust-policy.json` and create the role:

```bash
aws iam create-role \
  --role-name S3ReplicationRole \
  --assume-role-policy-document file://trust-policy.json
```

Attach the replication policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${S3_BUCKET_NAME}",
        "arn:aws:s3:::${BACKUP_S3_BUCKET}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      "Resource": [
        "arn:aws:s3:::${S3_BUCKET_NAME}/*",
        "arn:aws:s3:::${BACKUP_S3_BUCKET}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Resource": [
        "arn:aws:s3:::${S3_BUCKET_NAME}-replica/*",
        "arn:aws:s3:::${BACKUP_S3_BUCKET}-replica/*"
      ]
    }
  ]
}
```

## Step 3: Configure Replication Rules

```bash
# For Active Storage bucket
aws s3api put-bucket-replication \
  --bucket ${S3_BUCKET_NAME} \
  --replication-configuration '{
    "Role": "arn:aws:iam::ACCOUNT_ID:role/S3ReplicationRole",
    "Rules": [
      {
        "ID": "ActiveStorageReplication",
        "Status": "Enabled",
        "Priority": 1,
        "Filter": {},
        "Destination": {
          "Bucket": "arn:aws:s3:::'"${S3_BUCKET_NAME}"'-replica",
          "StorageClass": "STANDARD_IA"
        },
        "DeleteMarkerReplication": {
          "Status": "Enabled"
        }
      }
    ]
  }' \
  --region ap-northeast-1

# For Backup bucket
aws s3api put-bucket-replication \
  --bucket ${BACKUP_S3_BUCKET} \
  --replication-configuration '{
    "Role": "arn:aws:iam::ACCOUNT_ID:role/S3ReplicationRole",
    "Rules": [
      {
        "ID": "BackupReplication",
        "Status": "Enabled",
        "Priority": 1,
        "Filter": {
          "Prefix": "backups/"
        },
        "Destination": {
          "Bucket": "arn:aws:s3:::'"${BACKUP_S3_BUCKET}"'-replica",
          "StorageClass": "STANDARD_IA"
        },
        "DeleteMarkerReplication": {
          "Status": "Enabled"
        }
      }
    ]
  }' \
  --region ap-northeast-1
```

## Step 4: Verify Replication

```bash
# Check replication configuration
aws s3api get-bucket-replication --bucket ${S3_BUCKET_NAME}
aws s3api get-bucket-replication --bucket ${BACKUP_S3_BUCKET}

# Upload a test file and verify it appears in the replica
aws s3 cp test.txt s3://${BACKUP_S3_BUCKET}/test-replication.txt
# Wait a few minutes, then check
aws s3 ls s3://${BACKUP_S3_BUCKET}-replica/test-replication.txt --region ap-northeast-3
```

## Monitoring

- Enable S3 Replication Metrics in CloudWatch
- Set up alarms for replication latency > 15 minutes
- Monitor `s3:ReplicationLatency` and `s3:OperationsFailedReplication` metrics

## Failover Procedure

If the primary region (ap-northeast-1) becomes unavailable:

1. Update `AWS_REGION` environment variable to `ap-northeast-3`
2. Update `S3_BUCKET_NAME` to `{S3_BUCKET_NAME}-replica`
3. Update `BACKUP_S3_BUCKET` to `{BACKUP_S3_BUCKET}-replica`
4. Redeploy or restart the application

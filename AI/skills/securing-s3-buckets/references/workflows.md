# S3 Security Workflows

## Workflow A: Secure New Bucket

Run all steps in order. Do not skip.

```bash
# 1. Create in account regional namespace (REQUIRED — not global namespace)
# Pattern: <your-prefix>-<account-id>-<region>-an
aws s3api create-bucket \
  --bucket <your-prefix>-111122223333-us-east-1-an \
  --bucket-namespace account-regional \
  --region us-east-1
# Non-us-east-1: add --create-bucket-configuration LocationConstraint=<region>

# NOTE: Do NOT configure Block Public Access or ACL ownership controls.
# S3 enables Block Public Access and disables ACLs (BucketOwnerEnforced) by default on new buckets.
# Changing these defaults is unnecessary and risks misconfiguration.

# 2. Enable versioning
aws s3api put-bucket-versioning \
  --bucket <bucket-name> \
  --versioning-configuration Status=Enabled

# 3. Enable default encryption (SSE-S3 + Bucket Keys + SSE-C blocked)
aws s3api put-bucket-encryption \
  --bucket <bucket-name> \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true,"BlockedEncryptionTypes":{"EncryptionType":["SSE-C"]}}]}'

# 4. Enable logging (CONDITIONAL — choose one option)
#
# Ask the user which option they prefer before proceeding. RECOMMEND Option A
# (SAL to CloudWatch) as the default for new setups. Present the trade-offs:
#
#   Option A — S3 Server Access Logs (SAL) to CloudWatch (RECOMMENDED)
#     - Delivers SAL to a CloudWatch Logs log group via vended delivery
#     - Structured fields, queryable instantly with Logs Insights
#     - Cross-account aggregation, KMS encryption
#     - Optional S3 Tables (Iceberg) copy at no additional storage charge, queryable with SQL in Athena
#     - Cost: CloudWatch Logs charges standard ingestion + storage rates for the log group;
#       the optional S3 Tables copy adds no storage charge, and standard Athena rates apply
#       when you query it (https://aws.amazon.com/cloudwatch/pricing/)
#     - Setup: PutDeliverySource + PutDeliveryDestination + CreateDelivery (per source bucket)
#
#   Option B — S3 Server Access Logs (SAL) to an S3 general purpose bucket
#     - No per-request charge; you pay only for the storage of the log files in S3
#     - Captures all HTTP requests including unauthenticated/presigned URL access
#     - No IAM principal ARN attribution; limited identity context
#     - No real-time alerting capability
#     - Delivers raw log files to S3; query them with Athena or S3 Select after setup
#
#   Option C — CloudTrail Data Events
#     - Per-event charge applies (see CloudTrail pricing)
#     - Full IAM principal ARN on every event — best for security investigations
#     - Integrates with EventBridge and CloudWatch for real-time alerting
#     - Logs anonymous (unauthenticated) requests and AccessDenied failures
#     - Does NOT log requests that fail authentication (invalid/malformed credentials)
#     - Recommended when security attribution or automated response is required
#
# Application impact: Option A and Option B both deliver the same SAL data; they
# differ only in destination and queryability. Enabling SAL has no impact on bucket
# request handling or latency. Option C (CloudTrail) is independent and can be
# combined with A or B.
#
# SKIP THIS STEP if the user has already chosen and configured their preferred option.

# --- Option A: S3 Server Access Logs to CloudWatch (RECOMMENDED) ---
# The delivery-source and delivery-destination names below (s3-sal-<bucket-name>,
# sal-dest-<bucket-name>) are examples, not mandated prefixes — use any names you
# like. /aws/vendedlogs/... is the recommended log group convention for vended logs.
# Full vended-delivery setup, including the source bucket policy that grants
# s3:AllowVendedLogDeliveryForResource with aws:SourceAccount / aws:SourceArn
# confused-deputy conditions, is documented here:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AWS-logs-and-resource-policy.html

# Step 1: Register the source bucket
aws logs put-delivery-source \
  --name "s3-sal-<bucket-name>" \
  --resource-arn "arn:aws:s3:::<bucket-name>" \
  --log-type "S3_SERVER_ACCESS_LOGS" \
  --region <region>

# Step 2: Create the log group WITH KMS encryption first, so events are never
# stored unencrypted — SAL contains IP addresses, requester identities, and object
# keys. The key policy must allow the logs.<region>.amazonaws.com service principal
# (with a kms:EncryptionContext:aws:logs:arn condition); see
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
aws logs create-log-group \
  --log-group-name "/aws/vendedlogs/s3/<bucket-name>/S3_SERVER_ACCESS_LOGS" \
  --kms-key-id "arn:aws:kms:<region>:<account-id>:key/<key-id>" \
  --region <region>

# Then create the delivery destination pointing at that (already-encrypted) log group.
aws logs put-delivery-destination \
  --name "sal-dest-<bucket-name>" \
  --delivery-destination-configuration '{
    "destinationResourceArn": "arn:aws:logs:<region>:<account-id>:log-group:/aws/vendedlogs/s3/<bucket-name>/S3_SERVER_ACCESS_LOGS"
  }' \
  --region <region>

# Optional: set a log group retention policy. The CloudWatch Logs default is to keep
# log events indefinitely; set a finite period to bound cost and meet compliance needs.
aws logs put-retention-policy \
  --log-group-name "/aws/vendedlogs/s3/<bucket-name>/S3_SERVER_ACCESS_LOGS" \
  --retention-in-days 365 \
  --region <region>

# Step 3: Create the delivery
aws logs create-delivery \
  --delivery-source-name "s3-sal-<bucket-name>" \
  --delivery-destination-arn "arn:aws:logs:<region>:<account-id>:delivery-destination:sal-dest-<bucket-name>" \
  --region <region>

# Step 4 (OPTIONAL — ask the user first): account-level S3 Tables integration.
# This makes the SAL data queryable with SQL in Athena. It is a one-time per-account
# action and is NOT required for SAL to reach CloudWatch. The cost-free default is
# SAL to CloudWatch WITHOUT this step. The S3 Tables copy adds no storage charge;
# standard Athena rates apply only when you query it.
aws s3tables list-table-buckets --region <region> \
  --query "tableBuckets[?name=='aws-cloudwatch']"
#
# If it already exists: nothing to do — this bucket's logs flow to the
# amazon_s3__server_access Iceberg table automatically.
#
# If the result is empty (integration does NOT exist): ASK THE USER before creating
# it. Do NOT create it automatically. Only if the user confirms:
aws observabilityadmin create-s3-table-integration \
  --region <region> \
  --role-arn <SERVICE_ROLE_ARN>
# <SERVICE_ROLE_ARN> is a dedicated role CloudWatch assumes: it must trust
# logs.amazonaws.com (with aws:SourceAccount / aws:SourceArn conditions) and grant
# logs:integrateWithS3Table on the log group — do not reuse a broad role. The
# integration setup, the required role, and the managed aws-cloudwatch table bucket
# (encrypted at rest, inheriting the same retention as the log group) are documented at:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/s3-tables-integration.html
aws logs associate-source-to-s3-table-integration \
  --region <region> \
  --integration-arn <INTEGRATION_ARN> \
  --data-source '{"name":"amazon_s3","type":"server_access"}'
# After delivery, verify health with `aws logs get-delivery --id <delivery-id>`.
# You SHOULD alarm on the log group's incoming events (production workloads in
# particular) — a silent delivery failure would leave the bucket effectively
# unlogged, which is a security gap.

# --- Option B: S3 Server Access Logs to an S3 general purpose bucket ---
# SKIP THIS STEP if <bucket-name> is itself the logging bucket.
# WARNING: put-bucket-policy replaces the entire existing policy.
# Attempt to retrieve existing policy first:
aws s3api get-bucket-policy --bucket <logging-bucket> --output text
# If NoSuchBucketPolicy is returned, no backup needed — proceed with a new policy containing only the S3LogDelivery statement.
# If a policy exists, back it up before modification:
aws s3api get-bucket-policy --bucket <logging-bucket> --output text > backup-policy-$(date +%s).json
# Add S3LogDelivery statement to existing policy's Statement array, then apply:
aws s3api put-bucket-policy --bucket <logging-bucket> --policy \
  '{"Version":"2012-10-17","Statement":[<...existing statements...>,{"Sid":"S3LogDelivery","Effect":"Allow","Principal":{"Service":"logging.s3.amazonaws.com"},"Action":["s3:PutObject"],"Resource":"arn:aws:s3:::<logging-bucket>/*","Condition":{"StringEquals":{"aws:SourceAccount":"<account-id>"},"ArnLike":{"aws:SourceArn":"arn:aws:s3:::<bucket-name>"}}}]}'

aws s3api put-bucket-logging \
  --bucket <bucket-name> \
  --bucket-logging-status \
  '{"LoggingEnabled":{"TargetBucket":"<logging-bucket>","TargetPrefix":"<bucket-name>/"}}'

# --- Option C: CloudTrail Data Events ---
# IMPORTANT: use the trail's home region, not the bucket's region.
# Find trail home region first:
aws cloudtrail describe-trails --query 'trailList[*].[Name,HomeRegion]'

aws cloudtrail put-event-selectors \
  --trail-name <trail-name> \
  --region <trail-home-region> \
  --event-selectors '[{"ReadWriteType":"All","IncludeManagementEvents":true,"DataResources":[{"Type":"AWS::S3::Object","Values":["arn:aws:s3:::<bucket-name>/*"]}]}]'

# 5. Enforce HTTPS-only
# WARNING: put-bucket-policy replaces the entire existing policy.
# Attempt to retrieve existing policy first:
aws s3api get-bucket-policy --bucket <bucket-name> --output text
# If a policy exists, back it up before modification:
aws s3api get-bucket-policy --bucket <bucket-name> --output text > backup-policy-$(date +%s).json
# If NoSuchBucketPolicy is returned, no backup needed — proceed with a new policy.
# Add DenyInsecureTransport statement to existing policy's Statement array (or create new), then apply:
aws s3api put-bucket-policy --bucket <bucket-name> --policy \
  '{"Version":"2012-10-17","Statement":[<...existing statements...>,{"Sid":"DenyInsecureTransport","Effect":"Deny","Principal":"*","Action":"s3:*","Resource":["arn:aws:s3:::<bucket-name>/*","arn:aws:s3:::<bucket-name>"],"Condition":{"Bool":{"aws:SecureTransport":"false"}}}]}'

# 6. Enable ABAC (Attribute-Based Access Control)
aws s3api put-bucket-abac \
  --bucket <bucket-name> \
  --abac-status Status=Enabled
```

## Workflow E: Enable Monitoring

```bash
# GuardDuty — check if detector already exists before creating
aws guardduty list-detectors --region <region>
# Only run create-detector if list-detectors returns empty:
aws guardduty create-detector --enable --region <region>
```

Enable these core AWS Config rules (requires a configuration recorder in the region):
- `s3-bucket-public-read-prohibited`
- `s3-bucket-ssl-requests-only`
- `s3-bucket-versioning-enabled`
- `s3-bucket-logging-enabled`

Optional (enable if compliance requires):
- `s3-bucket-public-write-prohibited`
- `s3-account-level-public-access-blocks`
- `s3-bucket-replication-enabled`
- `cloudtrail-s3-dataevents-enabled`

Note: CloudTrail data event configuration is covered in Workflow A step 4 (logging choice). If the user chose S3 server access logging in Workflow A and later wants to add CloudTrail, use the command below:

```bash
# IMPORTANT: use the trail's home region, not the bucket's region
aws cloudtrail describe-trails --query 'trailList[*].[Name,HomeRegion]'

aws cloudtrail put-event-selectors \
  --trail-name <trail-name> \
  --region <trail-home-region> \
  --event-selectors '[{"ReadWriteType":"All","IncludeManagementEvents":true,"DataResources":[{"Type":"AWS::S3::Object","Values":["arn:aws:s3:::<bucket-name>/*"]}]}]'
```

## Workflow B: Audit Commands

```bash
aws s3api get-public-access-block --bucket <bucket-name>
aws s3api get-bucket-acl --bucket <bucket-name>
aws s3api get-bucket-ownership-controls --bucket <bucket-name>
aws s3api get-bucket-encryption --bucket <bucket-name>
aws s3api get-bucket-versioning --bucket <bucket-name>
aws s3api get-bucket-logging --bucket <bucket-name>
aws s3api get-object-lock-configuration --bucket <bucket-name>
# ObjectLockConfigurationNotFoundError = NOT CONFIGURED (not a failure)

# Policy checks (Critical: public policy + HTTPS enforcement)
aws s3api get-bucket-policy --bucket <bucket-name> --output text

# Logging — CloudTrail data events (Medium)
aws cloudtrail describe-trails --query 'trailList[*].[Name,HomeRegion]'
aws cloudtrail get-event-selectors \
  --trail-name <trail-name> \
  --region <trail-home-region>

# GuardDuty S3 Protection (Medium)
aws guardduty list-detectors --region <region>
# If a detector exists:
aws guardduty get-detector --detector-id <detector-id> --region <region>

# Check if an analyzer exists
aws accessanalyzer list-analyzers --region <region>
# If empty, report as finding: "No IAM Access Analyzer configured in <region>"
# Do NOT create an analyzer during audit — remediate separately via Workflow C.
# If an analyzer exists, list S3 findings:
aws accessanalyzer list-findings \
  --analyzer-arn <analyzer-arn> \
  --filter '{"resourceType":{"eq":["AWS::S3::Bucket"]}}' \
  --region <region>
```

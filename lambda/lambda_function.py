import json
import boto3
import datetime

sns = boto3.client('sns')
s3 = boto3.client('s3')
rds_data = boto3.client('rds-data')  # Use RDS Data API if using Aurora Serverless

# ✅ Update these with your values:
SNS_TOPIC_ARN = "arn:aws:sns:ap-south-1:<account-id>:log-alert-topic"
S3_BUCKET = "log-bucket-xxxx"
DB_USERNAME = "admin"  # Optional: for RDS data API
DB_PASSWORD = "admin12345"  # If using Secrets Manager
DB_NAME = "logdb"

def lambda_handler(event, context):
    timestamp = datetime.datetime.utcnow().isoformat()
    message = json.dumps(event)

    # ✅ Store log in S3
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=f"logs/log-{timestamp}.json",
        Body=message
    )

    # ✅ Check if log is critical
    if "ERROR" in message or "CRITICAL" in message or "FAILURE" in message:
        # Send SNS alert
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="🚨 Critical Log Alert",
            Message=message
        )

        # OPTIONAL: Store to RDS (if using RDS Data API)
        # rds_data.execute_statement(...)

    return {
        'statusCode': 200,
        'body': 'Log processed'
    }

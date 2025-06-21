provider "aws" {
  region = "ap-south-1"
}

# S3 Bucket for log archiving
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "log-bucket-${random_id.bucket_id.hex}"
  force_destroy = true
}

# SNS Topic for email alerts
resource "aws_sns_topic" "log_alerts" {
  name = "log-alert-topic"
}

# Replace with your email
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.log_alerts.arn
  protocol  = "email"
  endpoint  = "your-shalinibaghel766@gmail.com"  # 🔁 Change this
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "log_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "log-processor-fn"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
}

resource "aws_cloudwatch_log_subscription_filter" "log_filter" {
  name            = "lambda-log-trigger"
  log_group_name  = aws_cloudwatch_log_group.log_group.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.log_processor.arn
  depends_on      = [aws_lambda_function.log_processor]
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_processor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.log_group.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/app/logs"
  retention_in_days = 7
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds-subnet-group"
  subnet_ids = data.aws_subnets.available.ids

  tags = {
    Name = "RDS Subnet Group"
  }
}

# RDS Instance (MySQL)
resource "aws_db_instance" "mysql" {
  identifier              = "log-monitoring-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  name                    = "logdb"
  username                = "admin"
  password                = "admin12345"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
}

# EC2 Instance for Grafana
# Fetch Latest Amazon Linux 2 AMI (x86_64)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "grafana_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = "aws-key"  # 🔁 Replace with your actual key
  associate_public_ip_address = true

  tags = {
    Name = "grafana-monitor"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ../ansible/inventory"
  }
}

# Security Group for DB
resource "aws_security_group" "db_sg" {
  name        = "rds-allow"
  description = "Allow MySQL"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Limit to EC2's IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Subnet fetch
data "aws_subnets" "available" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

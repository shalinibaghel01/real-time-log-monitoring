#!/bin/bash
yum update -y
yum install -y git unzip curl wget

# Install Terraform
cd /tmp
wget https://releases.hashicorp.com/terraform/1.8.4/terraform_1.8.4_linux_amd64.zip
unzip terraform_1.8.4_linux_amd64.zip
mv terraform /usr/local/bin/
terraform -version

# Install AWS CLI (if not installed)
yum install -y awscli

# Clone your GitHub repo
cd /home/ec2-user
git clone https://github.com/shalinibaghel01/real-time-log-monitoring.git
chown -R ec2-user:ec2-user real-time-log-monitoring

# (Terraform apply ko manually run karna hoga after aws configure)

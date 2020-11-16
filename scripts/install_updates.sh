#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

function warn {
	if ! eval "$@"; then
		echo >&2 "WARNING: command failed \"$@\""
	fi
}

echo "Install ansible2"
sudo yum update -y
sudo yum install -y ansible --enablerepo=epel

echo "Install other tools"
warn "sudo yum install -y iptables-services net-tools"

echo "Enable IPtables"
warn "sudo systemctl enable iptables"
warn "sudo systemctl start iptables"

echo 'Downloading and installing SSM Agent' 
warn "sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"

echo 'Check SSM agent is running' 
warn "sudo systemctl status amazon-ssm-agent"

echo 'Downloading and installing amazon-cloudwatch-agent'
warn "sudo yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"

echo 'Starting cloudwatch agent'
warn "sudo amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/tmp/CWAgentParameters.json -s"

echo 'Install Amazon Inspector'
warn 'curl https://inspector-agent.amazonaws.com/linux/latest/install | sudo bash -x'


sudo yum install -y ruby unzip

wget https://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip

sudo unzip ec2-ami-tools.zip -d /usr/local/ec2

sudo touch /etc/profile.d/myenvvars.sh

sudo yum install kpartx -y

sudo yum install grub -y

sudo bash -c 'echo "export EC2_AMITOOL_HOME=/usr/local/ec2/ec2-ami-tools-1.5.7" >> /etc/profile.d/myenvvars.sh'
sudo bash -c 'echo "export PATH=/usr/local/ec2/ec2-ami-tools-1.5.7/bin:$PATH:" >> /etc/profile.d/myenvvars.sh'

export PATH=$PATH:/usr/sbin:/opt/aws/bin
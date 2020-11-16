#!/bin/bash

REGION="us-east-1"

function usage {
  cat <<EOF
  USAGE:  $0 [-h] [-i image_id] [-i type]
  eg,
          $0 -h                #usage
          $0                   #query last n images then let user select
          $0 -i ami-123e45     #use ami-12345
EOF
  exit
}

function die {
  # die with a message
  echo >&2 "$@"
  exit 1
}

function list_amis(){
  local region_name="$1"
  local account_id="$2"
  aws ec2 describe-images \
    --filters \
    Name=owner-id,Values=$account_id \
    Name=architecture,Values=x86_64 \
    Name=virtualization-type,Values=hvm \
    Name=root-device-type,Values=ebs \
    --query "reverse(sort_by(Images[*], &CreationDate)) [*].[CreationDate,ImageId,Name]" \
    --region "$region_name" \
    --output text
}



function is_ami_exist {
  local ami_id="$1"
  echo "checking if $ami_id exist"
  local output=$(aws ec2 describe-images \
    --filters \
    Name=image-id,Values=$ami_id \
    --query "Images[*].[CreationDate,ImageId,Name]" \
    --region "$REGION" \
    --output text)

  return $(echo "$output"| wc -l)
}

while getopts "hi:t:" o; do
  case "$o" in
    h) usage ;;
    i) opt_i=1; ami="$OPTARG" ;;
    i) opt_t=1; type="$OPTARG" ;;
    *) usage ;;
  esac
done

type="${type:-m4.large}"
sg="sg-921194d0"
ssh_key="amazon-linux2-ami"
iam_profile="Arn=arn:aws:iam::329935618861:instance-profile/SSMInstanceProfile"

if [ "$opt_i" == "1" ]; then
  # cli input with imageid
  is_ami_exist $ami && die "image doesnot exist"
else
  account_id=$(aws sts get-caller-identity --query "Account" --output text)
  last_ami=$(list_amis "$REGION" $account_id | head -n 1 | awk '{print $2}')

  echo "Latest AMI owned by current account: $last_ami"

fi

echo "Create a ec2 in default vpc"

ec2_id=$(aws ec2 run-instances --image-id $last_ami \
           --count 1 --instance-type $type --key-name $ssh_key\
           --security-group-ids $sg \
           --iam-instance-profile $iam_profile \
           --network-interfaces '[ { "DeviceIndex": 0, "DeleteOnTermination": true, "AssociatePublicIpAddress": true } ]' \
           --block-device-mappings '[ { "DeviceName":"/dev/xvda", "Ebs":{"DeleteOnTermination":true,"VolumeSize":10,"VolumeType":"gp2","KmsKeyId":"alias/aws/ebs","Encrypted":true} } ]' \
           --instance-initiated-shutdown-behavior terminate \
           --output text --query 'Instances[*].InstanceId')

aws ec2 create-tags --resources $ec2_id --tags Key=Name,Value=\"testvm-$(whoami)-test-ec2\"
echo "Waiting for instance to run"
aws ec2 wait instance-running --instance-ids "$ec2_id"
echo "EC2 $ec2_id is now running"

#aws ec2 associate-iam-instance-profile --instance-id ${ec2_id} --iam-instance-profile Name=bastion
ip_address=$(aws ec2 describe-instances --instance-ids "$ec2_id" --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo "IP address: $ip_address"
echo "ssh -i ~/.ssh/${ssh_key}.pem ec2-user@${ip_address}"
ssh -i ~/.ssh/${ssh_key}.pem ec2-user@${ip_address}

#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
SG_ID="sg-0c61fbce81bf52f18" # REPLACE WITH YOUR SG ID
ZONE_ID="Z057768411GBBUOBGRPG8"


for instance in $@
do
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids
         $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" 
         --query 'Instances[0].InstanceId' --output text)


#  get Private ip
    if [ $instance != frontend ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        echo "$instance is created with private ip $PRIVATE_IP"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        echo "$instance is created with public ip $PUBLIC_IP"
    fi

    echo "$instance: $IP"
done
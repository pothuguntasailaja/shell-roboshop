#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
SG_ID="sg-0c61fbce81bf52f18"
ZONE_ID="Z057768411GBBUOBGRPG8"
DOMAIN_NAME="daws86s.de"

for instance in $@
do

    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    # Get Private IP or Public IP

    if [ $instance != frontend ]; then

        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

        echo "$instance is created with private ip $IP"

        RECORD_NAME="$instance.$DOMAIN_NAME"

    else

        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

        echo "$instance is created with public ip $IP"

        RECORD_NAME="$DOMAIN_NAME"

    fi

    echo "$instance: $IP"

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
            \"Comment\": \"Updating record set\",
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 60,
                    \"ResourceRecords\": [{
                        \"Value\": \"$IP\"
                    }]
                }
            }]
        }"

done

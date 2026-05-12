#!/bin/bash

SG_ID="sg-04754d022bb5a7adb" # replace with your ID
AMI_ID="ami-0220d79f3f480ecf5" 
ZONE_ID="Z05902511NVRXMGRDURYV"
DOMAIN_NAME="dhruvadvith.online"

for instance in $@
do
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
    IP=$(
        aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[].Instances[].PublicIpAddress" \
        --output text
        
       )
       RECORD_NAME="$instance.$DOMAIN_NAME" # frontend.dhruvadvith.online
else
    IP=$(
        aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \   
        --query "Reservations[].Instances[].PrivateIpAddress" \
        --output text
       )
         RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.dhruvadvith.online
fi

echo "IP Adress: $IP"

aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating the A record for my website",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }  
    '
    echo "record updated for $instance"
done

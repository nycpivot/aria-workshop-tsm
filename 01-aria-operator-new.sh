#!/bin/bash

read -p "AWS Region Code (us-east-1): " aws_region_code
read -p "AWS Stack Name (tanzu-operator-stack): " stack_name

if [[ -z $aws_region_code ]]
then
    aws_region_code=us-east-1
fi

if [[ -z $stack_name ]]
then
    stack_name=tanzu-operator-stack
fi

#aws cloudformation delete-stack --stack-name $stack_name --region $aws_region_code 

aws cloudformation create-stack --stack-name $stack_name --region $aws_region_code \
    --template-body file://config/aria-operator-stack.yaml

aws cloudformation wait stack-create-complete --stack-name $stack_name --region $aws_region_code

aws cloudformation describe-stacks --stack-name $stack_name --region $aws_region_code \
    --query "Stacks[0].Outputs[?OutputKey=='PublicDnsName'].OutputValue" --output text

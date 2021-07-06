#!/bin/bash

DIR=$(git rev-parse --show-toplevel)/_deploy/
mkdir $DIR &>/dev/null
DEPLOY=deploy-$(date +%s).yaml

echo "Enter the ARN of the secret in AWS SecretsManager that contains your IPStack API Key."
echo -n "> "
read secret_arn
echo

echo "Enter the bucket were you will be storing your code. This is the bucket you specified while configuring AWS SAM"
echo -n "> "
read bucket
echo

# AWS no longer vends the requests module. We'll need to use pip3 package it with our code.
pip3 install requests -t ./whoami_lambda --upgrade

sam build

sam package --s3-bucket $bucket --output-template-file $DIR$DEPLOY 

sam deploy --template-file $DIR$DEPLOY --stack-name whoami-api-stack --capabilities CAPABILITY_IAM --parameter-overrides SecretArnParam="$secret_arn"

if [ $? -eq 0 ]; then
	echo "Checking API with cURL..."
	curl -s $(aws cloudformation describe-stacks --stack-name whoami-api-stack --query "Stacks[0].Outputs[0].OutputValue")| python -m json.tool
fi

#!/bin/bash
# Upload Lambda code to S3 and deploy Cloud Formation for the first time.
# After that, Github actions will update the Lambda code.
# Set aws access keys or profile using env variables, e.g. AWS_PROFILE=home
# Github actions TOKEN needs to be updated every day
set -e

if [ -z $1 ]; then
    echo "Error! You must specify env parmeter: test or prod"
    exit 1
fi
env=$1

zip -rj frontend.zip frontend/
zip -sf frontend.zip
zip -rj backend.zip backend/
zip -sf backend.zip
aws s3 cp frontend.zip s3://llamafilm.com/github/tesla_cmds_aws_lambda_frontend.zip
aws s3 cp backend.zip s3://llamafilm.com/github/tesla_cmds_aws_lambda_backend.zip

aws cloudformation create-stack --stack-name tesla-shortcuts-${env} \
    --template-body file://tesla-shortcuts-cloud-formation.yaml \
    --capabilities CAPABILITY_IAM \
    --parameters ParameterKey=Env,ParameterValue=${env}
echo "Waiting for stack creation..."
aws cloudformation wait stack-create-complete --stack-name tesla-shortcuts-${env}

echo "Complete.  Enter URL in config.json for iOS Shortcuts"
aws cloudformation describe-stacks --stack-name tesla-shortcuts-${env} \
    --query "Stacks[0].Outputs[?OutputKey=='LambdaURL'].OutputValue" --output text

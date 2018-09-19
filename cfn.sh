#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "Usage: ./cfn.sh deploy STACK_NAME TEMPLATE_FILE_NAME"
    echo "or ./cfn.sh delete STACK_NAME"
    exit 1
fi
SUBCMD=""

if [ "$1" == "deploy" ];then
  SUBCMD="cloudformation deploy --stack-name $2 --template-file $3"
elif [ "$1" == "delete" ];then
  SUBCMD="cloudformation delete-stack --stack-name $2"
else
  echo "Only deploy or delete is supported, run ./cfn.sh for help"
  exit 1
fi

DATE=$(date "+%Y%m%d")
#BACKUPNAME="${bamboo_TARGET}-${DATE}"
CURL="/usr/bin/curl -s"
AWS="$(which aws)"
METADATA="http://169.254.169.254/latest/meta-data/iam/security-credentials"

# max number of seconds to wait for ami to become available
MAX_WAIT_TIME=900

get_creds () {
  ROLENAME="dev_test"
  ACCESSID=$($CURL $METADATA/$ROLENAME | grep AccessKeyId | cut -d \" -f4)
  if [ $? -gt 0 ]; then
      echo "Error Retrieving AccessKeyId"
      exit 1
  fi
  ACCESSKEY=$($CURL $METADATA/$ROLENAME | grep SecretAccess | cut -d \" -f4)
  if [ $? -gt 0 ]; then
      echo "Error Retrieving SecretAccessKey"
      exit 1
  fi
  ACCESSTOKEN=$($CURL $METADATA/$ROLENAME | grep Token | cut -d \" -f4)
  if [ $? -gt 0 ]; then
      echo "Error Retrieving Token"
      exit 1
  fi
  export AWS_ACCESS_KEY_ID=$ACCESSID
    export AWS_SECRET_ACCESS_KEY=$ACCESSKEY
  export AWS_SESSION_TOKEN=$ACCESSTOKEN
}
get_creds

echo "Variables"
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
echo $AWS_SESSION_TOKEN

set -xe

#default to region us-west-2
#now run aws cli command to deploy, update or delete the stack
$AWS --region us-west-2 $SUBCMD
#if it's a delete then wait for it to complete, before exiting
if [ "$1" == "delete" ];then
  $AWS --region us-west-2 cloudformation wait stack-delete-complete --stack-name $2
fi

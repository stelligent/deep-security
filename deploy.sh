#!/usr/bin/env bash

set -e

source deploy.config

if [[ -z "$STACK_NAME" || \
  -z "$LAMBDA_BUCKET" || \
  -z "$LAMBDA_PREFIX" || \
  -z "$CONFIG_BUCKET" || \
  -z "$CONFIG_PREFIX" || \
  -z "$DS_HOSTNAME" ]]
then
  echo "" >&2
  echo "Required parameters missing in deploy.config." >&2
  echo "" >&2
  exit 1
fi

./build.sh

echo ""
echo "Packaging and deploying lambdas..."

aws cloudformation package \
  --template-file deep-security.yml \
  --s3-bucket "$LAMBDA_BUCKET" \
  --s3-prefix "$LAMBDA_PREFIX" \
  --output-template-file transformed.template

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file transformed.template \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    ConfigBucket="$CONFIG_BUCKET" \
    ConfigPrefix="$CONFIG_PREFIX" \
    DSUsernameKey="$DS_USERNAME_PARAM_STORE_KEY" \
    DSPasswordKey="$DS_PASSWORD_PARAM_STORE_KEY" \
    DSHostname="$DS_HOSTNAME" \
    DSPort="$DS_PORT" \
    DSTenant="$DS_TENANT" \
    DSIgnoreSslValidation="$DS_IGNORE_SSL_VALIDATION" \
    DSPolicy="$DS_POLICY" \
    DSControl="$DS_CONTROL"

./clean.sh

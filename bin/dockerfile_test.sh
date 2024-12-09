#!/bin/bash
set -euo pipefail

function help() {
  echo "Optionally builds the docker image and runs the tests against the development enviroment.

  Run in an authenticated shell with permission to access ssm params in
  forms-deploy using the gds-cli or aws-vault

  Usage: $0 <DOCKER IMAGE TO TEST>

  Example:
  gds aws forms-deploy-readonly -- $0 'existing-docker-image-tag'
  "
exit 1
}

if [[ "$1" == "help" ]]; then
  help
fi

IMAGE_TO_TEST="$1"

if [[ -z "$IMAGE_TO_TEST" ]]; then
  echo 'Building image'
  IMAGE_TO_TEST="test_e2e_$(date +%Y-%m-%d_%H-%M)"
  docker build -t "$IMAGE_TO_TEST" ../
fi

if [ -z "$FORMS_ADMIN_URL" ] || \
   [ -z "$PRODUCT_PAGES_URL" ] || \
   [ -z "$AUTH0_EMAIL_USERNAME" ] || \
   [ -z "$AUTH0_USER_PASSWORD" ] || \
   [ -z "$SETTINGS__GOVUK_NOTIFY__API_KEY" ]; then
  echo "Loading env vars from parameter store"
  source load_env_vars.sh
  set_e2e_env_vars 'dev'
  set_smoke_test_env_vars 'dev'
fi

echo 'Running the tests against dev environment'

env | grep AWS_ > ./env.list

docker run --env-file ./env.list --rm \
  -e FORMS_ADMIN_URL \
  -e PRODUCT_PAGES_URL \
  -e AUTH0_EMAIL_USERNAME \
  -e AUTH0_USER_PASSWORD \
  -e SETTINGS__GOVUK_NOTIFY__API_KEY \
  -e SMOKE_TEST_FORM_URL \
  -e FORMS_RUNNER_URL \
  -e S3_FORM_ID \
  "$IMAGE_TO_TEST"

rm -f ./env.list
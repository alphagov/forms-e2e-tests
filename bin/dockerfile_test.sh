#!/bin/bash
set -eo pipefail

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  IMAGE_TO_TEST="forms-e2e-tests:test_$(date +%Y%m%dT%H%M)"
  docker build -t "$IMAGE_TO_TEST" .
fi

# Map legacy environment variables to settings
export SETTINGS__FORMS_ADMIN__URL="${SETTINGS__FORMS_ADMIN__URL:-$FORMS_ADMIN_URL}"
export SETTINGS__FORMS_ADMIN__AUTH__USERNAME="${SETTINGS__FORMS_ADMIN__AUTH__USERNAME:-$AUTH0_EMAIL_USERNAME}"
export SETTINGS__FORMS_ADMIN__AUTH__PASSWORD="${SETTINGS__FORMS_ADMIN__AUTH__PASSWORD:-$AUTH0_USER_PASSWORD}"
export SETTINGS__FORMS_PRODUCT_PAGE__URL="${SETTINGS__FORMS_PRODUCT_PAGE__URL:-$PRODUCT_PAGES_URL}"
export SETTINGS__FORMS_RUNNER__URL="${SETTINGS__FORMS_RUNNER__URL:-$FORMS_RUNNER_URL}"

if [ -z "$SETTINGS__FORMS_ADMIN__URL" ] || \
   [ -z "$SETTINGS__FORMS_ADMIN__AUTH__USERNAME" ] || \
   [ -z "$SETTINGS__FORMS_ADMIN__AUTH__PASSWORD" ] || \
   [ -z "$SETTINGS__FORMS_PRODUCT_PAGE__URL" ] || \
   [ -z "$SETTINGS__GOVUK_NOTIFY__API_KEY" ]; then
  echo "Loading env vars from parameter store"
  source $SCRIPT_DIR/load_env_vars.sh
  set_e2e_env_vars 'dev'
  set_smoke_test_env_vars 'dev'
fi

echo 'Running the tests against dev environment'

env | grep -e AWS_ -e SETTINGS__ > ./env.list

docker run --env-file ./env.list --rm \
  -e SMOKE_TEST_FORM_URL \
  -e LOG_LEVEL=debug \
  -e TRACE=1 \
  "$IMAGE_TO_TEST"

rm -f ./env.list

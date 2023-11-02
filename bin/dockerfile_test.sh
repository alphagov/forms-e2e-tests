#!/bin/bash

function help() {
  echo "Builds the docker image and runs the tests against the development enviroment.

  Run in an authenticated shell with permission to access ssm params in
  forms-deploy using the gds-cli or aws-vault

  Usage: $0

  Example:
  gds-cli aws forms-deploy-readonly -- $0
  "
exit 1
}

if [[ "$1" == "help" ]]; then
  help
fi

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "No AWS credentials found"
  help
fi

echo 'Building image'
image_tag="test_e2e_$(date +%Y-%m-%d_%H-%M)"
docker build -t "$image_tag" ../

echo 'Running the tests against dev environment'
source load_env_vars.sh
set_env_vars 'dev'

docker run --rm \
  -e FORMS_ADMIN_URL \
  -e AUTH0_EMAIL_USERNAME \
  -e AUTH0_USER_PASSWORD \
  -e SETTINGS__GOVUK_NOTIFY__API_KEY \
  "$image_tag"


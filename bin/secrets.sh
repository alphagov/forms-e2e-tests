#!/bin/bash

function get_param() {
  path="$1"

  aws ssm get-parameter \
    --with-decrypt \
    --name "$path" \
    --output text \
    --query 'Parameter.Value'
}

function export_secrets() {
  local environment="$1"
  if [ -z "$environment" ]; then
    echo "usage 'set_env_vars dev|staging|production'"
    exit 1
  fi

  if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Could not access AWS resources; make sure you've assumed a role in the AWS account you're targeting." >&2
    exit 1
  fi

  export SETTINGS__FORMS_ENV="$environment"

  export SETTINGS__FORMS_ADMIN__AUTH__USERNAME="$(get_param /${environment}/automated-tests/e2e/auth0/email-username)"
  export SETTINGS__FORMS_ADMIN__AUTH__PASSWORD="$(get_param /${environment}/automated-tests/e2e/auth0/auth0-user-password)"
  export SETTINGS__GOVUK_NOTIFY__API_KEY="$(get_param /${environment}/automated-tests/e2e/notify/api-key)"
  export SETTINGS__GOVUK_ONE_LOGIN__USER_EMAIL="$(get_param /${environment}/automated-tests/e2e/one-login/user-email)"
  export SETTINGS__GOVUK_ONE_LOGIN__USER_PASSWORD="$(get_param /${environment}/automated-tests/e2e/one-login/user-password)"
  export SETTINGS__GOVUK_ONE_LOGIN__USER_OTP_SECRET_KEY="$(get_param /${environment}/automated-tests/e2e/one-login/user-otp-secret-key)"
  export SETTINGS__SUBMISSION_STATUS_API__SECRET="$(get_param /${environment}/automated-tests/e2e/runner/submission_status_api_shared_secret)"
}

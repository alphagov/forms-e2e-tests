#!/bin/bash

function admin_url() {
  local environment="$1"

  case $environment in
    "dev") echo "https://admin.dev.forms.service.gov.uk" ;;
    "staging") echo "https://admin.staging.forms.service.gov.uk" ;;
    "production") echo "https://admin.forms.service.gov.uk" ;;
    *)
      echo "Unknown environment: ${environment}"
      exit 1
      ;;
  esac
}

function product_pages_url() {
  local environment="$1"

  case $environment in
    "dev") echo "https://www.dev.forms.service.gov.uk" ;;
    "staging") echo "https://www.staging.forms.service.gov.uk" ;;
    "production") echo "https://www.forms.service.gov.uk" ;;
    *)
      echo "Unknown environment: ${environment}"
      exit 1
      ;;
  esac
}

function form_url() {
  local environment="$1"

  case $environment in
    "dev") echo "https://submit.dev.forms.service.gov.uk/form/11120/scheduled-smoke-test" ;;
    "staging") echo "https://submit.staging.forms.service.gov.uk/form/12148/scheduled-smoke-test" ;;
    "production") echo "https://submit.forms.service.gov.uk/form/2570/scheduled-smoke-test" ;;
    *)
      echo "Unknown environment: ${environment}"
      exit 1
      ;;
  esac
}

function get_param() {
  path="$1"

  aws ssm get-parameter \
    --with-decrypt \
    --name "$path" \
    --output text \
    --query 'Parameter.Value'
}

function set_e2e_env_vars() {
  local environment="$1"
  if [ -z "$environment" ]; then
    echo "usage 'set_env_vars dev|staging|production'"
    exit 1
  fi

  export FORMS_ADMIN_URL="$(admin_url $environment)"
  export PRODUCT_PAGES_URL="$(product_pages_url $environment)"
  export SETTINGS__GOVUK_NOTIFY__API_KEY="$(get_param /${environment}/automated-tests/e2e/notify/api-key)"
  export AUTH0_EMAIL_USERNAME="$(get_param /${environment}/automated-tests/e2e/auth0/email-username)"
  export AUTH0_USER_PASSWORD="$(get_param /${environment}/automated-tests/e2e/auth0/auth0-user-password)"
}

function set_smoke_test_env_vars() {
  local environment="$1"
  export SMOKE_TEST_FORM_URL="$(form_url "$environment")"
}

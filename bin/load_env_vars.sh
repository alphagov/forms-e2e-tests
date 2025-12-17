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

function runner_url() {
  local environment="$1"

  case $environment in
    "dev") echo "https://submit.dev.forms.service.gov.uk" ;;
    "staging") echo "https://submit.staging.forms.service.gov.uk" ;;
    "production") echo "https://submit.forms.service.gov.uk" ;;
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

function aws_account_id() {
  aws sts get-caller-identity --query Account --output text
}

function aws_s3_role_arn() {
  local environment="$1"
  local account_id="$(aws_account_id)"

  case $environment in
    "dev"|"staging"|"production") echo "arn:aws:iam::${account_id}:role/govuk-s3-end-to-end-test-${environment}" ;;
    *)
      echo "unknown environment: ${environment}"
      exit 1
      ;;
  esac
}

function aws_s3_bucket() {
  local environment="$1"

  case $environment in
    "dev"|"staging"|"production") echo "govuk-forms-submissions-to-s3-test" ;;
    *)
      echo "unknown environment: ${environment}"
      exit 1
      ;;
  esac
}

function s3_form_id() {
  local environment="$1"

  case $environment in
    "dev") echo "12457" ;;
    "staging") echo "13657" ;;
    "production") echo "5086" ;;
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
  export FORMS_RUNNER_URL="$(runner_url $environment)"
  export PRODUCT_PAGES_URL="$(product_pages_url $environment)"
  export SETTINGS__GOVUK_NOTIFY__API_KEY="$(get_param /${environment}/automated-tests/e2e/notify/api-key)"
  export AUTH0_EMAIL_USERNAME="$(get_param /${environment}/automated-tests/e2e/auth0/email-username)"
  export AUTH0_USER_PASSWORD="$(get_param /${environment}/automated-tests/e2e/auth0/auth0-user-password)"
  export S3_FORM_ID="$(s3_form_id $environment)"
  export AWS_S3_BUCKET="$(aws_s3_bucket $environment)"
  export SETTINGS__AWS__S3_SUBMISSION_IAM_ROLE_ARN="$(aws_s3_role_arn $environment)"
  export SETTINGS__SUBMISSION_STATUS_API__SECRET="$(get_param /${environment}/automated-tests/e2e/runner/submission_status_api_shared_secret)"
  export SETTINGS__FORMS_ENV="$environment"
}

function set_smoke_test_env_vars() {
  local environment="$1"
  export SMOKE_TEST_FORM_URL="$(form_url "$environment")"
  export SETTINGS__FORMS_ENV="$environment"
}

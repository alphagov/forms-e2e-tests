#!/bin/bash
set -e

# Change to the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v chromedriver &> /dev/null; then
  echo "Install chromedriver, see forms-e2e-tests/README.md"
  exit 1
fi

environment="$1"

if [[ -z "$environment" ]] || [[ "$1" == "help" ]] || [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "Runs the Capybara end-to-end tests for the given environment.

Run in an authenticated shell with permission to access ssm params in
gds-forms-deploy using the gds-cli or aws-vault

Usage: $0 dev|staging|production

Example:
gds-cli aws gds-forms-deploy-readonly -- $0 dev
"
  exit 0
fi

function admin_url() {
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

function get_param() {
  path="$1"

  aws ssm get-parameter \
    --with-decrypt \
    --name "$path" \
    --output text \
    --query 'Parameter.Value'
}

if [[ "$(admin_url)" =~ "Unknown" ]]; then
    exit 1
fi

export FORMS_ADMIN_URL="$(admin_url)"
export SIGNON_USERNAME="$(get_param /${environment}/smoketests/signon/username)"
export SIGNON_OTP="$(get_param /${environment}/smoketests/signon/secret)"
export SIGNON_PASSWORD="$(get_param /${environment}/smoketests/signon/password)"
export SETTINGS__GOVUK_NOTIFY__API_KEY="$(get_param /${environment}/smoketests/notify/api-key)"
export AUTH0_EMAIL_USERNAME="$(get_param /${environment}/smoketests/auth0/email-username)"
export AUTH0_GMAIL_ADDRESS="$(get_param /${environment}/smoketests/auth0/gmail-address)"
export AUTH0_GOOGLE_APP_PASSWORD="$(get_param /${environment}/smoketests/auth0/gmail-password)"

cd ..
bundle install

bundle exec rspec

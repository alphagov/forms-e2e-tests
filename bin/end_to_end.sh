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
forms-deploy using the gds-cli or aws-vault

Usage: $0 dev|staging|production

Example:
gds aws forms-deploy-readonly -- $0 dev
"
  exit 0
fi

source ./load_env_vars.sh
set_env_vars "$environment"

cd ..
bundle install

bundle exec rspec spec/features/complete_spec.rb

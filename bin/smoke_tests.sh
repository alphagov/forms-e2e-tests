#!/bin/bash
set -e

# Change to the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v chromedriver &> /dev/null; then
  echo "Install chromedriver, see forms-e2e-tests/README.md"
  exit 1
fi

if [[ "$1" == "help" ]] || [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "Runs the Capybara smoke tests against the production environment.

Run in an authenticated shell with permission to access ssm params in
forms-deploy using the gds-cli or aws-vault

Usage: $0

Example:
gds aws forms-production-readonly -- $0
"
  exit 0
fi

source ./load_env_vars.sh
set_env_vars "production"

cd ..
bundle install

bundle exec rspec spec/features/smoke_test*_spec.rb

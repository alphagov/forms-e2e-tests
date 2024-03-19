#!/bin/bash
set -e

# Change to the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v chromedriver &> /dev/null; then
  echo "Install chromedriver, see forms-e2e-tests/README.md"
  exit 1
fi

if [[ "$1" == "help" ]]; then
  echo "Runs the Capybara smoke tests against an environment.

Usage: $0 <dev|staging|production>
"
  exit 0
fi

source ./load_env_vars.sh
set_smoke_test_env_vars "$1"

cd ..
bundle install

bundle exec rspec spec/smoke_tests

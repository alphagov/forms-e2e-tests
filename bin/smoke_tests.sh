#!/bin/bash
set -e

# Change to the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ "$1" == "help" ]]; then
  echo "Runs the Capybara smoke tests against an environment.

Usage: $0 <dev|staging|production>
"
  exit 0
fi

cd ..
bundle install

bundle exec rspec spec/smoke_tests

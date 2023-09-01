# The end to end tests for the GOV.UK Forms service

## Introduction

This is a simple end-to-end test of the forms service.

It uses chrome to login to Forms Admin, creates a form, fills it out in the
runner and then deletes the form.

## Getting started

### Install

Make sure you have `chrome` and a matching version of `chromedriver` installed and in your path.

You can follow [these instructions](https://chromedriver.chromium.org/getting-started) or download it directly from https://googlechromelabs.github.io/chrome-for-testing/

Install the ruby dependencies:

```
bundle install
```

### Running the tests locally

You can run the tests against localhost using the following command: 

```
SKIP_SIGNON=1 FORMS_ADMIN_URL='http://localhost:3000/' bundle exec rspec
```

### Running the tests against remote environments

To run the tests against one of the standard environemnts you can use the end_to_end.sh script.

Run it in an authenticated shell with permission to access SSM params in gds-forms-deploy using the gds-cli or aws-vault

For example, to run the tests against the development environment, use:

```bash
gds-cli aws gds-forms-deploy-readonly bin/end_to_end.sh dev
```

Change `dev` to `staging` or `production` to run the tests against those environments.

### Debugging

When writing tests or when the tests fail unexpectedly it can be useful to see
the browser and pause them.

To show the browser set the environment variable `GUI` to a truthy value to run
chrome in visual rather than headless mode.

For example:

```
GUI=1 SKIP_SIGNON=1 FORMS_ADMIN_URL='http://localhost:3000/' bundle exec rspec
```

To open the debugger while running the tests, the [ruby debug gem](https://github.com/ruby/debug) is included.

Add the following within the specs at the line you would like the test to pause:

```ruby
debugger
```

You can then use the command line debugger to check the contents of variables and other debugging tasks. To continue the tests, type `continue` and press enter.

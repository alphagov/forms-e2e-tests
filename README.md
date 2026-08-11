# The end to end tests for the GOV.UK Forms service

## Introduction

This is a simple end-to-end test of the forms service.

It uses chrome to login to Forms Admin, creates a form, fills it out in the
runner and then deletes the form.

## Getting started

### Install

Make sure you have `chrome` and a matching version of `chromedriver` installed and in your path.

You can follow [these instructions](https://chromedriver.chromium.org/getting-started) or download it directly from [chrome for testing](https://googlechromelabs.github.io/chrome-for-testing/).

> [!TIP]
> If you're having trouble with flaky tests, try using Cuprite instead of ChromeDriver with `USE_CUPRITE=1`

Install the ruby dependencies:

```shell
bundle install
```

### Running the tests locally

The tests expect an active group to exist called "End to end tests", which the test user belongs as a group admin. This name can be overridden by setting the environment variable `SETTINGS__END_TO_END_TESTS__GROUP_NAME`.

#### Starting forms-runner

Forms-runner needs to be started with AWS credentials for the dev account in order to send submissions.

```shell
gds aws forms-dev-readonly --shell

ASSUME_DEV_IAM_ROLE=true ./bin/rails server
```

see the [README for forms-runner](https://github.com/govuk-forms/forms-runner?tab=readme-ov-file#getting-aws-credentials) for more details

#### Starting forms-admin

Forms-admin needs to be started with the Notify API key to send the submission email verification code:
```
SETTINGS__GOVUK_NOTIFY__API_KEY=<notify-api-key> ./bin/rails server
```

#### Running the tests

The tests then need to be run with AWS credentials for the dev account in order to check for the confirmation email.
You can run the tests against localhost using the following command:

```shell
gds aws forms-dev-readonly --shell

SETTINGS__GOVUK_NOTIFY__API_KEY=<your api key> bundle exec rake
```

### Choosing the browser automation protocol

By default these tests use Selenium and ChromeDriver to talk to Chrome browser. However, since Chrome 134 users of Capybara with ChromeDriver have been reporting intermittent `Node with given id` and similar errors (see https://github.com/teamcapybara/capybara/issues/2800).

As a potential workaround, you can use the [Cuprite] gem instead, by setting the environment variable `USE_CUPRITE`:

```shell
USE_CUPRITE=1 bundle exec rake
```

This is still an experimental change however, and needs more testing. In our automated pipelines we instead have pinned the version of Chrome used to a known good version.

[Cuprite]: https://github.com/rubycdp/cuprite

### Skipping the product pages

The end to end tests can be run without visiting the product pages by setting
the `SKIP_PRODUCT_PAGES` environment variable to `1`.

### Skipping the s3 submission test

The end to end tests can be run without testing a form with the `submission_type` of `s3` by setting the `SKIP_S3` environment variable to `1`.

### Skipping the file upload

The end to end tests can be run without testing a form with a file upload question by setting the `SKIP_FILE_UPLOAD` environment variable to `1`.

### Skipping receiving a copy of answers using GOV.UK One Login

The end to end tests can be run without testing receiving a copy of answers using GOV.UK One Login by setting the `SKIP_COPY_OF_ANSWERS` environment variable to `1`.

### Running the s3 submission test

The S3 submission tests use a form created by the forms-admin seed data locally. On remote environments, it uses forms configured manually by us, with the form ID passed in using the `SETTINGS__FORM_IDS__S3` environment variable.

The S3 tests need to assume an IAM role to access the submissions S3 bucket. Run the e2e tests in an AWS shell so we can assume this role:

```shell
gds aws forms-dev-readonly --shell

SKIP_S3=0 bundle exec rake
```

### Running the test to get a copy of answers using GOV.UK One Login

forms-runner needs to be started with the One Login client details. See the [README for forms-runner](https://github.com/govuk-forms/forms-runner#configuring-govuk-one-login) to configure these.

We need to run tests with the One Login sign in details for the test user by setting the `SETTINGS__GOVUK_ONE_LOGIN__USER_PASSWORD` and `SETTINGS__GOVUK_ONE_LOGIN__USER_OTP_SECRET_KEY` environment variables. Obtain the values for these from the [AWS parameter store](https://github.com/govuk-forms/forms-deploy/blob/c586c1368dd9acbe79a819aa4c32a5ef3229d686/infra/modules/automated-test-parameters/parameters.tf#L49) on the dev environment. 

The tests need to assume an IAM role to check the email with a copy of the answers is delivered to an S3 bucket. Run the e2e tests in an AWS shell so we can assume this role:

```shell
gds aws forms-dev-readonly --shell

SKIP_COPY_OF_ANSWERS=0 \
SETTINGS__GOVUK_ONE_LOGIN__USER_PASSWORD=<password> \
SETTINGS__GOVUK_ONE_LOGIN__USER_OTP_SECRET_KEY=<secret key> \
bundle exec rake
```

### Running the tests against remote environments

To run the tests against one of the standard environments you can use the end_to_end.sh script.

Run it in an authenticated shell with permission to access SSM params in the desired environment.

For example, to run the tests against the development environment, use:

```bash
gds aws forms-dev-readonly -- bin/end_to_end.sh dev
```

Change `dev` to `staging` or `production` to run the tests against those environments.

### Debugging

When writing tests or when the tests fail unexpectedly it can be useful to see
the browser and pause them.

To show the browser set the environment variable `GUI` to a truthy value to run
chrome in visual rather than headless mode.

For example:

```shell
GUI=1 bundle exec rake
```

To open the debugger while running the tests, the [ruby debug gem](https://github.com/ruby/debug) is included.

Add the following within the specs at the line you would like the test to pause:

```ruby
debugger
```

You can then use the command line debugger to check the contents of variables and other debugging tasks. To continue the tests, type `continue` and press enter.

#### Logging

If the tests are running in an environment where you can't see the browser (for
instance in our continuous deployment pipeline), you can configure the quantity
of log messages the end to end tests output.

You can choose what level messages to print when running the tests by setting
the `LOG_LEVEL` environment variable. The allowed levels are `debug`, `info`, `warn`,
`error`, and `fatal`. The default level is warn.

As an example, to run the end to end tests with the info level:

```bash
LOG_LEVEL=info bundle exec rake
```

For additional detail in the logging you can enable tracing, which prints every
line in the source code of the tests as it is reached.

To enable tracing, set the `TRACE` environment variable:

```bash
TRACE=1 bundle exec rake
```

### Setup in new environments

The tests expect an editor user exist with an Auth0 database connection configured and a username and password set.

The user should belong to an active group, called "End to end tests", as a group admin to allow publishing a form.

The login details should be stored in AWS parameter store. See bin/load_env_vars.sh for configuring the enviroment varibles required.

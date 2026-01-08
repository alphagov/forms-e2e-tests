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

#### GOV.UK Notify API keys

Set in your environment:

```shell
export SETTINGS__GOVUK_NOTIFY__API_KEY=<your api key>
```

Ensure both the forms-admin and forms-runner services are also configured to use the Notify API - see their respective READMEs for details.

### Running the tests locally

The tests expect an active group to exist called "End to end tests", which the test user belongs as a group admin. This name can be overridden by setting the environment variable `SETTINGS__END_TO_END_TESTS__GROUP_NAME`.

You can run the tests against localhost using the following command:

```shell
bundle exec rake
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

### Running the file upload test

Forms-runner needs to be started with the AWS credentials for the dev account for the file upload test to pass, as follows:

- `gds aws forms-dev-readonly --shell`
- `ASSUME_DEV_IAM_ROLE=true SETTINGS__GOVUK_NOTIFY__API_KEY='<notify-api-key>' ./bin/rails server`
- see the [README for forms-runner](https://github.com/alphagov/forms-runner?tab=readme-ov-file#getting-aws-credentials) for more details

### Running the s3 submission test

You will need:

- an aws iam role.
  - This is the role with permissions to upload to and delete from an s3 bucket, and that you have permission to assume. When running the tests locally, this will be the [s3 end to end test role](https://github.com/alphagov/forms-deploy/blob/2a8720380219ac854d3c1d008e6b82af67e4a7b2/infra/modules/forms-runner/s3-end-to-end-test-role.tf#L2) in the dev environment,
- an s3 bucket.
  - This bucket should be set up so that the above role can access it. When running the tests locally, this will be [the submissions test bucket](https://github.com/alphagov/forms-deploy/blob/2a8720380219ac854d3c1d008e6b82af67e4a7b2/infra/deployments/deploy/tools/submissions-to-s3-test-bucket.tf#L4) created in the deploy account.

To run the tests:

- in `forms-runner`:
  - add your govuk_notify.api_key and aws.s3_submission_iam_role to settings.local.yml
  - start the server using an iam role that can assume the above role (eg: `gds aws forms-dev-readonly -- bundle exec rails s`)
- in `forms-admin`
  - add your govuk_notify.api_key to settings.local.yml
  - ensure the seeded s3 submission test form is set up correctly, and run the following rake task:
    - `rake "forms:submission_type:set_to_s3[2, ${the name of the submission bucket}, ${the aws account id where the bucket lives}, ${the region}, csv]"`
  - start the server (without aws)
- in `forms-e2e-tests`
  - start an aws shell:
    - `gds aws forms-dev-readonly --shell`
  - run the end to end tests tests:

```shell
SETTINGS__AWS__FILE_UPLOAD_S3_BUCKET_NAME=${ the name of the s3 bucket }\
SETTINGS__AWS__S3_SUBMISSION_IAM_ROLE_ARN=${ the iam role arn } \
SETTINGS__GOVUK_NOTIFY__API_KEY=${ your notify api key here } \
SKIP_AUTH=1 \
SKIP_PRODUCT_PAGES=1 \
LOG_LEVEL=info \
bundle exec rspec spec/end_to_end
```

### Running the tests against remote environments

To run the tests against one of the standard environemnts you can use the end_to_end.sh script.

Run it in an authenticated shell with permission to access SSM params in forms-deploy using the gds-cli or aws-vault

For example, to run the tests against the development environment, use:

```bash
gds aws forms-deploy-readonly bin/end_to_end.sh dev
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

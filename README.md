# A demo of running e-2-e tests using ruby and capybara

## Introduction

This is a simple end-to-end test of the forms service.

It uses chrome to login to signon, create a form, fill it out, then delete the form.

## Getting started

### Install

Make sure you have `chrome` and `chromedriver` installed and in the path.

You can follow [these instructions](https://chromedriver.chromium.org/getting-started) or [this macOs specific guide](https://www.kenst.com/installing-chromedriver-on-mac-osx/).

Install the ruby dependencies:

```
bundle install
```

### Running tests
You will need to export the following environment variables for the tests to be to able to login to staging.

You can get the OTP by generating a new code in staging - this might not be very secure though, so ideally use a dedicated account.

```
SIGNON_USERNAME=
SIGNON_PASSWORD=
SIGNON_OTP=
FORMS_ADMIN_URL='https://admin.staging.forms.service.gov.uk/'
```

Then run the `bundle exec rspec` to run the tests.

## Debugging

Set the environment variable `GUI` to a truthy value to run chrome in visual rather than headless mode. For example:

```
GUI=1 bundle exec rspec
```

To debug errors, the [ruby debug gem](https://github.com/ruby/debug) is included.

For example, add the following within the specs at the line you would like the test to pause.

```ruby
debugger
```

You can then use the command line debugger to check the contents of variables
and other debugging tasks. To continue the tests, type `continue` and press
enter.

You can run the tests against localhost using the following command: 

```
SKIP_SIGNON=1 FORMS_ADMIN_URL='http://localhost:3000/' bundle exec rspec
```

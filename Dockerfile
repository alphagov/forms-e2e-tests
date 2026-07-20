# TODO: restore to latest version of Alpine once we can use the latest Chromium again (see https://github.com/teamcapybara/capybara/issues/2800)
# https://trello.com/c/bFuui8d7/3458-unpin-alpine-version-in-forms-e2e-tests-once-chromedriver-issue-is-fixed
ARG ALPINE_VERSION=3.24
ARG RUBY_VERSION=3.4.9

ARG DOCKER_IMAGE_DIGEST=sha256:d48f27097c1e2f3bf01d62d55bc063a292cf18d9a39ee6f0cb27cf37fc39f53c

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}@${DOCKER_IMAGE_DIGEST}

ENV BUNDLE_SIMULATE_VERSION=4

RUN apk update
RUN apk upgrade --available

RUN apk add chromium chromium-chromedriver libc6-compat build-base yaml-dev aws-cli

RUN adduser -D ruby

RUN mkdir /app && chown -R ruby:ruby /app
WORKDIR /app

USER ruby

COPY --chown=ruby:ruby .ruby-version .
COPY --chown=ruby:ruby Gemfile* .

RUN bundle config set --local without development
RUN bundle install

COPY --chown=ruby:ruby . .

CMD ["bundle", "exec", "rspec"]

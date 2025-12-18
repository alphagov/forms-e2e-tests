# TODO: restore to latest version of Alpine once we can use the latest Chromium again (see https://github.com/teamcapybara/capybara/issues/2800)
ARG ALPINE_VERSION=3.22
ARG RUBY_VERSION=3.4.8

ARG DOCKER_IMAGE_DIGEST=sha256:c7687b054738956d3e409fbb335ffa711c9b2dab87a57a2f89d9141746b9fdde

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}@${DOCKER_IMAGE_DIGEST}

WORKDIR /app
RUN apk update
RUN apk upgrade --available

RUN apk add chromium chromium-chromedriver libc6-compat build-base yaml-dev aws-cli

RUN adduser -D ruby
USER ruby

COPY --chown=ruby:ruby . ./

RUN bundle config set --local without development
RUN bundle install

CMD ["bundle", "exec", "rspec"]

# TODO: restore to latest version of Alpine once we can use the latest Chromium again (see https://github.com/teamcapybara/capybara/issues/2800)
ARG ALPINE_VERSION=3.20
ARG RUBY_VERSION=3.4.1

ARG DOCKER_IMAGE_DIGEST=sha256:d799fbab7da903c8e709be7df0734b8593ef884242cd34b7a7369b527f06aec3

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}@${DOCKER_IMAGE_DIGEST}

WORKDIR /app
RUN apk update
RUN apk upgrade --available

RUN apk add chromium libc6-compat build-base

RUN adduser -D ruby
USER ruby

COPY --chown=ruby:ruby . ./

RUN bundle install

CMD ["bundle", "exec", "rspec"]

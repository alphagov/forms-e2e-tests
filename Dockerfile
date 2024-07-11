ARG ALPINE_VERSION=3.19
ARG RUBY_VERSION=3.3.4

ARG DOCKER_IMAGE_DIGEST=sha256:37f4c0f791aa3c791dc2bcf052201ffd6a644fcc545aaf5ceac8231c702c7e9d

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}@${DOCKER_IMAGE_DIGEST}

WORKDIR /app
RUN apk update
RUN apk upgrade --available

RUN apk add chromium chromium-chromedriver libc6-compat build-base

RUN adduser -D ruby
USER ruby

COPY --chown=ruby:ruby . ./

RUN bundle install

CMD ["bundle", "exec", "rspec"]

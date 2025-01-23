ARG ALPINE_VERSION=3.21
ARG RUBY_VERSION=3.3.7

ARG DOCKER_IMAGE_DIGEST=sha256:abe1aeac9b4c223a94873162d2d5d0f6c47efea9c5a8b40deadf3c1b55c5a1b3

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

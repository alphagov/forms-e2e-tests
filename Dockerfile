ARG ALPINE_VERSION=3.19
ARG RUBY_VERSION=3.3.1

ARG DOCKER_IMAGE_DIGEST=sha256:92047b87f9a122a10b22fba43ad647969a5c1ca43da663abebf5718dce1ab6a0

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

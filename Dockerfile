ARG ALPINE_VERSION=3.18
ARG RUBY_VERSION=3.3.1

ARG DOCKER_IMAGE_DIGEST=sha256:d907735cff25973a6c904d3b221914fabb217f279c807c53a807d6668c6b2acb

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

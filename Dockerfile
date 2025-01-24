ARG ALPINE_VERSION=3.21
ARG RUBY_VERSION=3.4.1

ARG DOCKER_IMAGE_DIGEST=sha256:e5c30595c6a322bc3fbaacd5e35d698a6b9e6d1079ab0af09ffe52f5816aec3b

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

ARG ALPINE_VERSION=3.19
ARG RUBY_VERSION=3.2.3

ARG DOCKER_IMAGE_DIGEST=sha256:a709ff05ff5e471ab0f824487d9b5777f36850694981c61d10d29290daad735c

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

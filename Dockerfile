ARG ALPINE_VERSION=3.19
ARG RUBY_VERSION=3.2.2

ARG DOCKER_IMAGE_DIGEST=sha256:3696ef2978429ec1f66e6f0688c3ce249ffb1a2f6da57b8fe82ecacb4125731d

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

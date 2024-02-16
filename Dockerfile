ARG ALPINE_VERSION=3.18
ARG RUBY_VERSION=3.2.2

ARG DOCKER_IMAGE_DIGEST=sha256:198e97ccb12cd0297c274d10e504138f412f90bed50c36ebde0a466ab89cf526

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

# TODO: restore to latest version of Alpine once we can use the latest Chromium again (see https://github.com/teamcapybara/capybara/issues/2800)
ARG ALPINE_VERSION=3.20
ARG RUBY_VERSION=3.4.4

ARG DOCKER_IMAGE_DIGEST=sha256:78223c2421bbd1e133fc6e126cf632c50b31c8728cbdbdae5742881c13c73350

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}@${DOCKER_IMAGE_DIGEST}

RUN apk update
RUN apk upgrade --available

RUN apk add chromium chromium-chromedriver libc6-compat build-base yaml-dev aws-cli

RUN adduser -D ruby

RUN mkdir /app && chown -R ruby:ruby /app
WORKDIR /app

USER ruby

COPY --chown=ruby:ruby .ruby-version .
COPY --chown=ruby:ruby Gemfile* .

RUN bundle config set --local without development
RUN bundle install

COPY --chown=ruby:ruby . .

CMD ["bundle", "exec", "rspec"]

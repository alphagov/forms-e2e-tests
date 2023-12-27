FROM ruby:3.3.0-alpine3.19@sha256:203b3087530e9cb117d8aab9b49bb766253fd8a6606a0d7520a591c7a3d992f7

WORKDIR /app
RUN apk update
RUN apk upgrade --available

RUN apk add chromium chromium-chromedriver libc6-compat build-base

RUN adduser -D ruby
USER ruby

COPY --chown=ruby:ruby . ./

RUN gem install bundler -v 2.4.21
RUN bundle install

CMD ["bundle", "exec", "rspec"]

FROM ruby:3.0

RUN gem install bundler:2.3.7

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY . .

RUN bundle install

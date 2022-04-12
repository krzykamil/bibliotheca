
FROM ruby:3.0.1

RUN apt-get update -qq && apt-get install -y build-essential
RUN apt-get install -y --no-install-recommends libjemalloc2

RUN mkdir /app
WORKDIR   /app

COPY ./Gemfile      /app
COPY ./Gemfile.lock /app

ENV BUNDLE_PATH /tmp/bundle
RUN gem install pg
RUN bundle install

ENV RACK_ENV production
ENV DOCKER   1

COPY . /app

EXPOSE 9292

CMD ./run

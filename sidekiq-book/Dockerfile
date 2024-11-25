FROM ruby:3.2.2

WORKDIR /app/
RUN apt update && apt upgrade -y && apt install -y postgresql-client postgresql-client-common libpq-dev
COPY ./Gemfile* /app/
RUN bundle install

EXPOSE 3000

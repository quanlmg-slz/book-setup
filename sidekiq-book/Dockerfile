FROM ruby:3.2.2

WORKDIR /app/
RUN apt update && apt upgrade -y
RUN apt install -y postgresql-client \
                    postgresql-client-common \
                    libpq-dev
RUN apt install -y npm && npm install -g yarn
RUN apt install -y chromium chromium-driver
COPY ./Gemfile* /app/
RUN bundle install

EXPOSE 3000

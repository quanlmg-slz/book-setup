# This is for actual use. See Dockerfile.dx for local dev
FROM ruby:3.2.2

WORKDIR /app/

ENV BINDING="0.0.0.0"
ENV PORT=4000
EXPOSE 4000

COPY . /app/

RUN bin/setup

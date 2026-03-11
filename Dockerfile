# syntax=docker/dockerfile:1

# ip_attribute CI container — runs rspec against the AR version matrix.
# Not a production runtime — this gem is a library, not a service.
#
# Usage:
#   docker compose run --rm test
#   AR_VERSION=7.2 docker compose run --rm test
#
# Matrix builds via docker-bake.hcl or CI workflow.
ARG RUBY_VERSION=3.4.9

FROM ruby:${RUBY_VERSION}-slim AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        build-essential git pkg-config \
        libyaml-dev libffi-dev \
    && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# jemalloc for memory efficiency in test runs
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends libjemalloc2 \
    && rm -rf /var/cache/apt/* /var/lib/apt/lists/*
ENV LD_PRELOAD=libjemalloc.so.2
ENV MALLOC_CONF="dirty_decay_ms:1000,narenas:2"

ARG APP_UID=10001
ARG APP_GID=10001
RUN groupadd -g ${APP_GID} appuser \
    && useradd -u ${APP_UID} -g appuser -m -s /bin/bash appuser

WORKDIR /app

COPY --link Gemfile ip_attribute.gemspec ./
COPY --link lib/ip_attribute/version.rb lib/ip_attribute/version.rb

ARG AR_VERSION=""
ENV AR_VERSION=${AR_VERSION}

RUN bundle install --jobs 4

COPY --link --chown=10001:10001 . .

USER 10001:10001

CMD ["bundle", "exec", "rspec", "--format", "progress"]

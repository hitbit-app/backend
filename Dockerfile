ARG MIX_ENV=dev
ARG APP_NAME=hitbit
ARG MIX_HOME=/opt/mix
ARG HEX_HOME=/opt/hex

FROM elixir:1.9-alpine AS base
ARG MIX_ENV
ARG MIX_HOME
ARG HEX_HOME

WORKDIR /opt/build

RUN apk add --no-cache \
        make \
        gcc \
        libc-dev \
        inotify-tools \
    && mix local.hex --force \
    && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN HEX_HTTP_TIMEOUT=240 mix deps.get && mix deps.compile

COPY . .

RUN mix compile

ENV MIX_ENV="${MIX_ENV}"
ENV MIX_HOME="${MIX_HOME}"
ENV HEX_HOME="${HEX_HOME}"

FROM base AS dev

CMD mix ecto.create && mix ecto.migrate && mix phx.server

FROM base AS test

CMD mix test

FROM base AS build
ARG MIX_ENV
ARG MIX_HOME
ARG HEX_HOME

RUN mix phx.digest && mix release

FROM alpine:3.9 AS deploy
ARG MIX_ENV=prod
ARG APP_NAME

WORKDIR /opt/app

RUN apk add --no-cache ncurses-libs

COPY --from=build "/opt/build/_build/${MIX_ENV}/rel/${APP_NAME}/" ./

ENV APP_NAME="${APP_NAME}"
CMD \
    "bin/${APP_NAME}" eval "Hitbit.Utils.Release.migrate" \
    && "bin/${APP_NAME}" start

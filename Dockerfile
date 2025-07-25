ARG MIX_ENV=prod
ARG ELIXIR_VERSION=1.18.4

FROM elixir:${ELIXIR_VERSION}-alpine AS build

ARG MIX_ENV
# Erlang flags for container building
ENV MIX_ENV=${MIX_ENV} ERL_AFLAGS="+JMsingle true"
RUN mkdir /opt/app
WORKDIR /opt/app
COPY mix.exs .
COPY mix.lock .
RUN mix do deps.get, deps.compile


FROM elixir:${ELIXIR_VERSION}-alpine AS dev

RUN mkdir /opt/app
RUN mkdir /opt/build
COPY --from=build /opt/app/_build /opt/build/_build
COPY --from=build /opt/app/deps /opt/build/deps
RUN apk add bash
RUN mix local.hex --force
WORKDIR /opt/app

ENTRYPOINT [ "priv/dev_launch.sh" ]

FROM build AS release-build

# Erlang flags for container building
ENV MIX_ENV=prod ERL_AFLAGS="+JMsingle true"

COPY config ./config
COPY lib ./lib
COPY test ./test
COPY priv ./priv

RUN mix release

FROM elixir:${ELIXIR_VERSION}-alpine AS prod

ENV MIX_ENV=prod
RUN mkdir --parents /opt/app/data
WORKDIR /opt/app
COPY --from=release-build /opt/app/_build .
ENV PATH="/opt/app/prod/rel/discord_bot/bin:${PATH}"
WORKDIR /opt/app/data
CMD ["discord_bot", "start"]

FROM bitwalker/alpine-elixir:latest AS build

ENV MIX_ENV=prod

COPY mix.exs .
COPY mix.lock .
RUN mix deps.get
RUN mix deps.compile

COPY config ./config
COPY lib ./lib
COPY test ./test

RUN mix release

FROM bitwalker/alpine-elixir:latest AS runtime

ENV STATE_CONFIG="${HOME}data/state_config.json"
COPY --from=build "$HOME"_build .
RUN mkdir data
COPY state_config.json ./data
RUN chown -R default: ./prod ./data
USER default
ENV PATH="${HOME}prod/rel/discord_bot/bin:${PATH}"
WORKDIR ${HOME}data
CMD ["discord_bot", "start"]

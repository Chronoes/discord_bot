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

COPY --from=build "$HOME"_build .
RUN chown -R default: ./prod
USER default
ENV PATH="${HOME}prod/rel/discord_bot/bin:${PATH}"
VOLUME [ "./players" ]
CMD ["discord_bot", "start"]

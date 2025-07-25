#!/bin/bash
# Run in container to copy deps to main runtime folder

rm -r _build deps
cp -ar /opt/build/deps /opt/build/_build .

elixir --sname discord_bot --cookie monster -S mix run --no-halt

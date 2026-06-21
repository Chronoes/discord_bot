# DiscordBot

DiscordBot is an OSRS-focused Discord bot that tracks player activity and provides quick player stats directly in a server. Original name, I know.

## What it can do

- `/kc <boss>`: show group and player kill counts for a boss using TempleOSRS data.
- `/oof [date]`: show death totals (PvM and PK), optionally since a specific date.
- Watch configured channels for RuneLite Dink plugin's `Player Death` embeds and store deaths automatically.
- Detect TempleOSRS competition links, trigger member daily datapoint refreshes, and flag users who no longer exist or name has changed.

## Configuration

Create `config/runtime.exs` from `config/runtime.example.exs` and set at least:

- Discord bot token: Must be created on [Discord Developer Portal](https://discord.com/developers/applications)
- Your Discord user ID (`my_id`): for bot messages to owner

### Create the SQLite database

The app uses `discord_bot.sqlite` as its database file.

Create the database before starting the bot:

```bash
mix ecto.create
mix ecto.migrate
```

If you run with Docker, create and migrate the database in the mounted data directory first:

```bash
mkdir -p /opt/discord_bot
docker build --target build --tag osrs-discord-bot:latest-build .
alias bot-run='docker run -it --rm -v /opt/discord_bot:/opt/app/data osrs-discord-bot:latest-build'

bot-run mix ecto.create
bot-run mix ecto.migrate
```

## Run with Docker

```bash
docker compose up -d --build
```

## Run migrations

Stop the bot before migrating because SQLite files should not be migrated while in active use.

```bash
bot-run mix ecto.migrate
```

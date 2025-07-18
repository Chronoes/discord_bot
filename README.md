# DiscordBot

Make sure **config/runtime.exs** is accessible. Example of required parameters is in **config/runtime.example.exs**.
Use Docker Compose to run this bot

```bash
docker compose up -d --build
```

## Run migrations

Build just build stage as image and use it to run migrations. Stop bot before running migrations
because shouldn't migrate an open SQLite file
```bash
docker build --target build --tag osrs-discord-bot:latest-build .
alias bot-run='docker run -it --rm -v /opt/discord_bot/discord_bot.sqlite:/opt/app/discord_bot.sqlite osrs-discord-bot:latest-build'
# Check status
bot-run mix ecto.migrations
# migrate
bot-run mix ecto.migrate
```

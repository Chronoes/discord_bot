# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :discord_bot,
  ecto_repos: [DiscordBot.Repo],
  # Discord user ID of the bot owner, used for DMs and other personal messages
  my_id: nil

config :nostrum,
  token: "",
  gateway_intents: [
    :direct_messages,
    :guild_messages,
    :message_content
  ],
  ffmpeg: nil

config :discord_bot, DiscordBot.Repo, database: "discord_bot.sqlite", wal_auto_check_point: 20

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :exirc_example, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:exirc_example, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).

import_config "#{config_env()}.exs"

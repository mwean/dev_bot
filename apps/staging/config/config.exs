use Mix.Config

config :slack, token: System.get_env("SLACK_TOKEN")

config :staging, slack_client: Slack.Bot
config :staging, slack_send: Slack.Sends
config :staging, timezone: "America/Los_Angeles"
config :staging, ecto_repos: [Staging.Repo]

config :staging, Staging.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "dev_bot_staging",
  hostname: "localhost",
  port: "5432"

import_config "#{Mix.env}.exs"

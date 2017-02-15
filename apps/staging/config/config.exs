use Mix.Config

config :staging, slack_client: Slack.Bot
config :staging, slack_send: Slack.Sends
config :staging, timezone: "America/Los_Angeles"
config :staging, ecto_repos: [Staging.Repo]

config :staging, Staging.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "dev_bot",
  hostname: "localhost",
  port: "5432"

import_config "#{Mix.env}.exs"

use Mix.Config

config :staging, slack_client: FakeSlack.Bot
config :staging, slack_send: FakeSlack.Sends

config :staging, Staging.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "dev_bot_staging_test",
  hostname: "localhost",
  port: "5432",
  pool: Ecto.Adapters.SQL.Sandbox

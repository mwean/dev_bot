use Mix.Config

config :slack, token: System.get_env("SLACK_TOKEN") || raise("Missing SLACK_TOKEN variable")

config :staging, Staging.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

use Mix.Config

config :slack, token: System.get_env("SLACK_TOKEN") || "slack_token"

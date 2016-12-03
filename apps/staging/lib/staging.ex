defmodule Staging do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    slack_client = Application.get_env(:staging, :slack_client)

    children = [
      worker(slack_client, [Staging.Bot, [], Application.get_env(:slack, :token), %{name: :slack}]),
      worker(Staging.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: Staging.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def today do
    Application.get_env(:staging, :timezone)
    |> Timex.now
    |> Timex.to_date
  end
end

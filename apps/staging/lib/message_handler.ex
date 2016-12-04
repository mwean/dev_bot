defmodule Staging.MessageHandler do
  @callback match?(String.t) :: boolean
  @callback respond(Slack.State, Map.t) :: any

  defmacro __using__(_) do
    quote do
      @behaviour Staging.MessageHandler
      @slack Application.get_env(:staging, :slack_send)
    end
  end
end

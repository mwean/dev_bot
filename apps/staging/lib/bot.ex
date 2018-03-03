require Logger

defmodule Staging.Bot do
  alias Staging.{AddServer, ListServers, ReserveServer, UpdateServer, ReleaseServer, ArchiveServer}

  @slack Application.get_env(:staging, :slack_send)
  @handlers [AddServer, ListServers, ReserveServer, UpdateServer, ReleaseServer, ArchiveServer]

  def handle_event(message = %{type: "message", text: message_text, user: user_id}, slack, state) do
    Logger.info("Message received: \"#{message_text}\" from #{slack.users[user_id][:name]}(#{user_id})")
    if for_me?(message_text, slack), do: handle_message(message, slack)

    {:ok, state}
  end
  def handle_event(_, _, state), do: {:ok, state}

  defp for_me?(message_text, slack) do
    Regex.match?(~r/^\s*(?:<@#{slack.me.id}>|#{slack.me.name})/, message_text)
  end

  defp handle_message(message, slack) do
    @handlers
    |> Enum.find(fn(handler) -> handler.match?(message.text) end)
    |> respond_to_message(message, slack)
  end

  defp respond_to_message(nil, _, _), do: Logger.info("No handler matched message")
  defp respond_to_message(handler, message, slack) do
    Logger.info("Handler #{inspect handler} matched")
    handler.respond(message, slack)
  end

  def handle_info({:message, text, channel}, slack, state) do
    @slack.send_message(text, channel, slack)
    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}

  def handle_connect(_, state), do: {:ok, state}
  def handle_close(_, _, _), do: :close
end

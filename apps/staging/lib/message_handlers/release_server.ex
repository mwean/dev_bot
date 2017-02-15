defmodule Staging.ReleaseServer do
  alias Staging.{Repo, Server, MessageHandler}
  use MessageHandler

  @pattern ~r/\s+release\s+([\w-]+)/i

  def match?(message_text), do: Regex.match?(@pattern, message_text)

  def respond(message, slack) do
    [_, server_name] = Regex.run(@pattern, message.text)
    release_server(server_name, message.user)
    |> @slack.send_message(message.channel, slack)
  end

  defp release_server(server_name, user_id) do
    case Repo.get_by(Server, name: server_name) do
      nil ->
        "I'm sorry, but I don't know that server. Add it with \"staging add #{server_name}\""
      server ->
        case Server.release(server, user_id) do
          :ok -> "Ok, #{server.name} is now available"
          :not_reserved -> "I'm sorry, but you don't have #{server.name} reserved"
        end
    end
  end
end

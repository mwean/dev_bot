defmodule Staging.AddServer do
  alias Staging.{Repo, Server, MessageHandler}
  use MessageHandler

  @pattern ~r/\s+add\s+([\w-]+)/i

  def match?(message_text), do: Regex.match?(@pattern, message_text)

  def respond(message, slack) do
    [_, server_name] = Regex.run(@pattern, message.text)
    add_server(server_name)
    |> @slack.send_message(message.channel, slack)
  end

  defp add_server(server_name) do
    case Repo.exists?(Server, name: server_name) do
      true -> "I'm sorry, but that server already exists"
      false ->
        Repo.insert!(%Server{name: server_name})
        "Ok, I added server \"#{server_name}\""
      end
  end
end

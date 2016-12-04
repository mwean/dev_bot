defmodule Staging.UpdateServer do
  alias Staging.{Repo, Server, MessageHandler}
  use MessageHandler

  @pattern ~r/\s+set\s+(\w+)\s+(?:to )?(\w+)\s+on\s+([\w-]+)/i

  def match?(message_text), do: Regex.match?(@pattern, message_text)

  def respond(message, slack) do
    [_, attr, value, server_name] = Regex.run(@pattern, message.text)
    update_server(attr, value, server_name)
    |> @slack.send_message(message.channel, slack)
  end

  defp update_server(attr, value, server_name) do
    case Repo.get_by(Server, name: server_name) do
      nil ->
        "I'm sorry, but I don't know that server. Add it with \"staging add #{server_name}\""
      server ->
        case Repo.update(server_change(server, attr, value)) do
          {:ok, _} ->
            "Ok, #{server.name} now has #{attr} #{value}"
          {:error, _} ->
            "I'm sorry, but that didn't work :("
        end
    end
  end

  defp server_change(server, "prod", "true") do
    Ecto.Changeset.change(server, prod_data: true)
  end

  defp server_change(server, "prod", "false") do
    Ecto.Changeset.change(server, prod_data: false)
  end
end

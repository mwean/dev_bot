defmodule Staging.ArchiveServer do
  alias Staging.{Server, MessageHandler}
  use MessageHandler

  @pattern ~r/\s+archive\s+([\w-, ]+)/i

  def match?(message_text), do: Regex.match?(@pattern, message_text)

  def respond(message, slack) do
    [_, server_names] = Regex.run(@pattern, message.text)

    String.split(server_names, ~r/[, ]+/)
    |> load
    |> archive
    |> build_response
    |> reply(message.channel, slack)
  end

  defp load(server_names), do: Server.with_name(server_names)

  defp archive(servers) do
    {_, updated} = Server.archive_all(servers)
    updated
  end

  defp build_response([]), do: "I'm sorry, but I couldn't find a server named that"

  defp build_response(servers) do
    "Ok, I archived #{server_names_list(servers)}"
  end

  defp server_names_list(servers) do
    Enum.map(servers, fn(server) -> server.name end)
    |> Enum.join(", ")
  end

  defp reply(message, channel, slack), do: @slack.send_message(message, channel, slack)
end

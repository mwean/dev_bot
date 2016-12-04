defmodule Staging.ReserveServer do
  alias Staging.{Repo, Server, MessageHandler}
  use MessageHandler

  @pattern ~r/\s+reserve\s+?(?:([\w-]+)\s+)?until\s+(.*)/i

  def match?(message_text), do: Regex.match?(@pattern, message_text)

  def respond(message, slack) do
    [_, server_name, end_date_str] = Regex.run(@pattern, message.text)
    reserve_server(server_name, end_date_str, message)
    |> @slack.send_message(message.channel, slack)
  end

  defp reserve_server(server_name, end_date_str, message) when is_binary(end_date_str) do
    end_date = parse_date(end_date_str)
    reserve_server(server_name, end_date, message)
  end

  defp reserve_server("", end_date, message) do
    case Server.reserve(user_id: message.user, end_date: end_date) do
      {:ok, server} -> success_message(server, end_date)
      :none_available -> "I'm sorry, but there are no servers available"
    end
  end

  defp reserve_server(server_name, end_date, message) do
    case Repo.get_by(Server, name: server_name) do
      nil ->
        "I'm sorry, but I don't know that server. Add it with \"staging add #{server_name}\""
      server ->
        case Server.reserve(server, message.user, end_date) do
          :ok -> success_message(server, end_date)
          :not_available -> "I'm sorry, but #{server.name} is not available"
        end
    end
  end

  defp success_message(server, end_date) do
    end_date_str = format_date(end_date)
    "Ok, you have #{server.name} reserved until #{end_date_str}"
  end

  defp parse_date(date_str) do
    Timex.parse!(date_str, "{YYYY}-{M}-{D}")
    |> Timex.to_date
  end

  defp format_date(date) do
    Timex.format!(date, "%-m/%-d", :strftime)
  end
end

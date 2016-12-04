defmodule Staging.ListServers do
  alias Staging.{Repo, Server, MessageHandler}
  use MessageHandler

  def match?(message_text), do: Regex.match?(~r/\s+list/i, message_text)

  def respond(message, slack) do
    build_response(slack)
    |> @slack.send_message(message.channel, slack)
  end

  defp build_response(slack) do
    case Repo.all(Server.with_active_reservation |> Server.order_by_name) do
      [] -> "I don't know any servers. Add some with \"staging add <server>\""
      servers ->
        ["Here are the servers I know about:" | display_server_list(servers, slack)]
        |> Enum.join("\n")
    end
  end

  defp display_server_list(servers, slack) do
    Enum.map servers, fn(server) ->
      "• #{server.name}"
      |> display_prod_data(server)
      |> display_reservation(server, slack)
    end
  end

  defp display_prod_data(str, %Server{prod_data: prod_data}) when prod_data == true, do: str <> " (w/ Prod Data)"
  defp display_prod_data(str, _), do: str

  defp display_reservation(str, %Server{active_reservation: nil}, _), do: str
  defp display_reservation(str, %Server{active_reservation: active_reservation}, slack) do
    reserved_user = slack.users[active_reservation.user_id]
    user_name = reserved_user[:real_name] || reserved_user[:name]
    {:ok, reservation_end_str} = Timex.format(active_reservation.end_date, "%-m/%-d", :strftime)

    str <> " Reserved by #{user_name} until #{reservation_end_str}"
  end
end

require Logger

defmodule Staging.Bot do
  @slack Application.get_env(:staging, :slack_send)

  def handle_event(message = %{type: "message", text: message_text}, slack, state) do
    Logger.info("Message received: \"#{message_text}\"")
    bot_pattern = "(?:<@#{slack.me.id}>|#{slack.me.name})"
    add_matches = Regex.run(~r/#{bot_pattern}\s+add\s+([\w-]+)/i, message_text)
    add_server(add_matches, message, slack)

    if message_text =~ ~r/#{bot_pattern}\s+list/i, do: list_servers(message, slack)

    reserve_matches = Regex.run(~r/#{bot_pattern} reserve ?([\w-]+)? until (.*)/i, message_text)
    reserve_server(reserve_matches, message, slack)

    update_server_matches = Regex.run(~r/#{bot_pattern} set (\w+) (?:to )?(\w+) on ([\w-]+)/, message_text)
    update_server(update_server_matches, message, slack)

    {:ok, state}
  end
  def handle_event(_, _, state), do: {:ok, state}

  defp add_server([_, server_name], message, slack) do
    reply = case Staging.Repo.exists?(Staging.Server, name: server_name) do
      true -> "I'm sorry, but that server already exists"
      false ->
        Staging.Repo.insert!(%Staging.Server{name: server_name})
        "Ok, I added server \"#{server_name}\""
      end

    @slack.send_message(reply, message.channel, slack)
  end
  defp add_server(match, _, _) when match == nil, do: nil

  defp list_servers(message, slack) do
    reply = case Staging.Repo.all(Staging.Server.with_active_reservation |> Staging.Server.order_by_name) do
      [] -> "I don't know any servers. Add some with \"staging add <server>\""
      servers ->
        ["Here are the servers I know about:" | display_server_list(servers, slack)]
        |> Enum.join("\n")
    end

    @slack.send_message(reply, message.channel, slack)
  end

  defp reserve_server([_, "", end_date_str], message, slack) do
    end_date = Timex.parse!(end_date_str, "{YYYY}-{M}-{D}") |> Timex.to_date

    reply = case Staging.Server.reserve(user_id: message.user, end_date: end_date) do
      {:ok, server} ->
        end_date_str = Timex.format!(end_date, "%-m/%-d", :strftime)
        "Ok, you have #{server.name} reserved until #{end_date_str}"
      :none_available -> "I'm sorry, but there are no servers available"
    end

    @slack.send_message(reply, message.channel, slack)
  end

  defp reserve_server([_, server_name, end_date_str], message, slack) do
    case Staging.Repo.get_by(Staging.Server, name: server_name) do
      nil ->
        "I'm sorry, but I don't know that server. Add it with \"staging add #{server_name}\""
        |> @slack.send_message(message.channel, slack)
      server ->
        end_date = Timex.parse!(end_date_str, "{YYYY}-{M}-{D}") |> Timex.to_date

        reply = case Staging.Server.reserve(server, message.user, end_date) do
          :ok ->
            end_date_str = Timex.format!(end_date, "%-m/%-d", :strftime)
            "Ok, you have #{server.name} reserved until #{end_date_str}"
          :not_available -> "I'm sorry, but #{server.name} is not available"
        end

        @slack.send_message(reply, message.channel, slack)
    end
  end
  defp reserve_server(_, _, _), do: nil

  defp update_server([_, attr, value, server_name], message, slack) do
    case Staging.Repo.get_by(Staging.Server, name: server_name) do
      nil ->
        "I'm sorry, but I don't know that server. Add it with \"staging add #{server_name}\""
        |> @slack.send_message(message.channel, slack)
      server ->
        reply = case Staging.Repo.update(server_change(server, attr, value)) do
          {:ok, _} ->
            "Ok, #{server.name} now has #{attr} #{value}"
          {:error, _} ->
            "I'm sorry, but that didn't work :("
        end

        @slack.send_message(reply, message.channel, slack)
    end
  end
  defp update_server(_, _, _), do: nil

  defp server_change(server, "prod", "true") do
    Ecto.Changeset.change(server, prod_data: true)
  end

  defp server_change(server, "prod", "false") do
    Ecto.Changeset.change(server, prod_data: false)
  end

  def handle_info({:message, text, channel}, slack, state) do
    @slack.send_message(text, channel, slack)
    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}

  defp display_server_list(servers, slack) do
    Enum.map servers, fn(server) ->
      "• #{server.name}"
      |> display_prod_data(server)
      |> display_reservation(server, slack)
    end
  end

  defp display_prod_data(str, %Staging.Server{prod_data: prod_data}) when prod_data == true, do: str <> " (w/ Prod Data)"
  defp display_prod_data(str, _), do: str

  defp display_reservation(str, %Staging.Server{active_reservation: nil}, _), do: str
  defp display_reservation(str, %Staging.Server{active_reservation: active_reservation}, slack) do
    reserved_user = slack.users[active_reservation.user_id]
    user_name = reserved_user[:real_name] || reserved_user[:name]
    {:ok, reservation_end_str} = Timex.format(active_reservation.end_date, "%-m/%-d", :strftime)

    str <> " Reserved by #{user_name} until #{reservation_end_str}"
  end

  def handle_connect(_, state), do: {:ok, state}
  def handle_close(_, _, _), do: :close
end

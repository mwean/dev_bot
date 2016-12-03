defmodule FakeSlack.Bot do
  def start_link(bot_handler, _, _, _) do
    Agent.start_link(fn -> %{bot_handler: bot_handler} end, name: __MODULE__)
  end

  def set_slack(slack) do
    Agent.update(__MODULE__, &Map.put(&1, :slack, slack))
  end
end

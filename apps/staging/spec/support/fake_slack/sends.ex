defmodule FakeSlack.Sends do
  def start_link do
    Agent.start_link(fn -> %{messages: []} end, name: __MODULE__)
  end

  def send_message(message, channel, slack) do
    Agent.update __MODULE__, fn(state) ->
      %{state | messages: [{message, channel, slack} | state.messages]}
    end
  end

  def messages do
    Agent.get(__MODULE__, &(&1.messages))
  end
end

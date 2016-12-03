require IEx

defmodule HaveReceivedAssertion do
  use ESpec.Assertions.Interface

  defp match(mod, args) do
    actual_messages = mod.messages
    {any_message_matches?(actual_messages, args), actual_messages}
  end

  defp success_message(_, _args, _result, _positive) do
    ""
  end

  defp error_message(mod, args, result, positive) do
    to = if positive, do: "to", else: "not to"
    "Expected `#{inspect mod}` #{to} have received message `#{inspect args}`, but only received '#{inspect result}'."
  end

  defp any_message_matches?(actual_messages, args) do
    Enum.any? actual_messages, fn(message) ->
      all_args_match?(args, Tuple.to_list(message))
    end
  end

  defp all_args_match?(expected_args, actual_args) do
    Enum.zip(expected_args, actual_args)
    |> Enum.all?(&args_match?/1)
  end

  defp args_match?({{:matcher, _, matcher}, actual}), do: matcher.(actual)
  defp args_match?({expected, actual}), do: expected == actual
end

defmodule CustomAssertions do
  def have_received(args) do
    {HaveReceivedAssertion, args}
  end

  def string_matching(pattern) do
    {:matcher, "a string matching #{inspect(pattern)}", fn(str) -> Regex.match?(pattern, str) end}
  end
end

{:ok, _} = Application.ensure_all_started(:ex_machina)
Ecto.Adapters.SQL.Sandbox.mode(Staging.Repo, :manual)

ESpec.configure fn(config) ->
  if System.get_env("CI") do
    output_path = Path.expand("#{System.get_env("CIRCLE_WORKING_DIRECTORY")}/_build/test/espec/junit.xml")
    IO.puts output_path

    config.formatters [
      {ESpec.Formatters.Doc, %{}},
      {ESpec.JUnitFormatter, %{out_path: output_path}}
    ]
  end
end

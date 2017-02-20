{:ok, _} = Application.ensure_all_started(:ex_machina)
Ecto.Adapters.SQL.Sandbox.mode(Staging.Repo, :manual)

ESpec.configure fn(config) ->
  if System.get_env("CIRCLECI") do
    config.formatters [
      {ESpec.Formatters.Doc, %{}},
      {ESpec.JUnitFormatter, %{out_path: "#{System.get_env("CIRCLE_TEST_REPORTS")}/espec/junit.xml"}}
    ]
  end
end

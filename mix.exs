defmodule DevBot.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      aliases: aliases,
      preferred_cli_env: [
        espec: :test,
        spec: :test
      ]
    ]
  end

  defp deps do
    []
  end

  defp aliases do
    [
      spec: ["ecto.create --quiet", "ecto.migrate", "espec"],
      test: ["spec"]
    ]
  end
end

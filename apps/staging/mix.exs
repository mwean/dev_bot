defmodule Staging.Mixfile do
  use Mix.Project

  def project do
    [
      app: :staging,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      preferred_cli_env: [espec: :test],
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps
    ]
  end

  def application do
    [
      applications: [:logger, :ecto, :postgrex, :slack, :timex],
      mod: {Staging, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "spec/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:slack, "~> 0.9.0"},
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.11"},
      {:ex_machina, "~> 1.0", only: :test},
      {:timex, "~> 3.0"},
      {:espec, "~> 1.2", only: :test}
    ]
  end
end

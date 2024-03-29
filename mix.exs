defmodule SyncedTomatoes.MixProject do
  use Mix.Project

  def project do
    [
      app: :synced_tomatoes,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps() ++ test_deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:sasl, :logger],
      mod: {SyncedTomatoes.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:jsonrs, "~> 0.3"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:construct, "== 3.0.0-rc.0"},
      {:uuid, "~> 1.1"},
    ]
  end

  defp test_deps do
    [
      {:ex_machina, "~> 2.7", only: :test},
      {:mint_web_socket, "~> 1.0", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:mox_env, "~> 1.0", only: :test},
      {:credo, "~> 1.7", only: [:test], runtime: false}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create --quiet", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end

defmodule SubmitBlock.MixProject do
  use Mix.Project

  def project do
    [
      app: :submit_block,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_abi, "~> 0.5.1"},
      {:ex_rlp, "~> 0.5.3"},
      {:ethereumex, "~> 0.6.4"},
      {:ex_secp256k1, "~> 0.1.2"},
      {:briefly, git: "https://github.com/CargoSense/briefly.git", only: [:test]},
      {:yaml_elixir, "~> 2.4.0", only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

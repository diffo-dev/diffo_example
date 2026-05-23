# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.2.3"
  @name "DiffoExample"
  @description "Examples for Diffo TMF Service and Resource Manager"
  @github_url "https://github.com/diffo-dev/diffo-example"

  def project do
    [
      app: :diffo_example,
      version: @version,
      name: @name,
      description: @description,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      package: package(),
      # ex_doc
      source_url: "https://github.com/diffo-dev/diffo_example/",
      homepage_url: "http://diffo.dev/diffo_example/",
      docs: [main: "readme", extras: ["README.md"]],
      elixirc_paths: elixirc_paths(Mix.env()),
      # agent stuff
      usage_rules: usage_rules(),
      # hex.pm stuff
      deps: deps(),
      docs: &docs/0,
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DiffoExample.Application, []}
    ]
  end

  defp diffo_version(default_version) do
    case System.get_env("DIFFO_VERSION") do
      nil -> default_version
      "local" -> [path: "../diffo"]
      "main" -> [git: "https://github.com/diffo-dev/diffo.git"]
      "dev" -> [git: "https://github.com/diffo-dev/diffo.git", branch: "dev"]
      version -> "~> #{version}"
    end
  end

  def docs do
    [
      homepage_url: @github_url,
      source_url: @github_url,
      source_ref: "v#{@version}",
      main: "readme",
      logo: "logos/diffo.jpg",
      extras: [
        "README.md": [title: "Guide"],
        "documentation/domains/diffo_example_nbn.livemd": [title: "NBN Livebook"],
        "documentation/domains/nbn.md": [title: "The NBN Domain"],
        "documentation/how_to/setup_mcp.md": [title: "Setup the MCP server"],
        "LICENSES/MIT.md": [title: "License"]
      ],
      groups_for_extras: [
        Domains: ~r"documentation/domains",
        "How To": ~r"documentation/how_to",
        DSLs: ~r"documentation/dsls"
      ]
    ]
  end

  defp package do
    [
      name: :diffo_example,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{
        "GitHub" => @github_url,
        "Author's home page" => "https://www.diffo.dev"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:diffo, diffo_version("~> 0.4.1")},
      {:ash_ai, "~> 0.6"},
      {:plug_cowboy, "~> 2.7"},
      {:picosat_elixir, "~> 0.2.0"},
      {:simple_sat, ">= 0.0.0"},
      {:usage_rules, "~> 1.0", only: [:dev]},
      {:req, "~> 0.5"},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases() do
    [
      test: ["ash.setup --quiet", "test"],
      setup: "ash.setup",
      docs: [
        "docs",
        "spark.replace_doc_links"
      ],
      "spark.formatter": [
        "format .formatter.exs"
      ]
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp usage_rules do
    # Example for those using claude.
    [
      file: "CLAUDE.md",
      # rules to include directly in CLAUDE.md
      usage_rules: ["usage_rules:all"],
      skills: [
        location: ".claude/skills",
        # build skills that combine multiple usage rules
        build: [
          "ash-framework": [
            description:
              "Use this skill working with Ash Framework or any of its extensions. Always consult this when making any domain changes, features or fixes.",
            # Include all Ash dependencies
            usage_rules: [:ash, ~r/^ash_/]
          ],
          "diffo-framework": [
            description:
              "Use this skill working with Diffo or any related non-Ash Diffo components. Understand the provider extension and assigner.",
            # Include all Diffo dependencies
            usage_rules: [:diffo, ~r/^diffo_/]
          ]
        ]
      ]
    ]
  end
end

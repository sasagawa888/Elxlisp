defmodule Elxlisp.MixProject do
  use Mix.Project

  def project do
    [
      app: :elxlisp,
      version: "0.1.0",
      elixir: "~> 1.7",
      description: "Lisp1.5 interpreter and compiler",
      deps: deps(),

      # Docs
      name: "Elxlisp",
      source_url: "https://github.com/sasagawa888/Elxlisp",
      start_permanent: Mix.env() == :prod,
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ],
      package: [
        files: [
          "lib",
          "README.md",
          "mix.exs"
        ],
        maintainers: ["Kenichi Sasagawa"],
        licenses: ["modified BSD"],
        links: %{"GitHub" => "https://github.com/sasagawa888/Elxlisp"}
      ]
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
      # {:ex_doc, "~> 0.21.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

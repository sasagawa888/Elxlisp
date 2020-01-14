defmodule Elxlisp.MixProject do
  use Mix.Project

  def project do
    [
      app: :elxlisp,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Lisp1.5 interpreter and compiler",
      package: [
        maintainers: ["Kenichi Sasagawa"],
        licenses: ["BSD"],
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

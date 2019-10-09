defmodule Mix.Tasks.App.Name do
  use Mix.Task

  @shortdoc "Prints app name"
  def run(_) do
    Mix.Project.config()
    |> Keyword.get(:app)
    |> Atom.to_string()
    |> Mix.shell().info()
  end
end

defmodule Mix.Tasks.App.Version do
  use Mix.Task

  @shortdoc "Prints app version"
  def run(_) do
    Mix.Project.config()
    |> Keyword.get(:version)
    |> Mix.shell().info()
  end
end

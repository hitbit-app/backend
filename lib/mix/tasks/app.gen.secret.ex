defmodule Mix.Tasks.App.Gen.Secret do
  use Mix.Task

  alias HitBit.Utils.Input
  alias HitBit.Utils.Rand

  defp app_name do
    Mix.Project.config()
    |> Keyword.get(:app)
    |> Atom.to_string()
  end

  defp camel_app_name, do: Macro.camelize(app_name())

  defp router_module, do: camel_app_name() <> "Web.Router"

  defp endpoint_module, do: camel_app_name() <> "Web.Endpoint"

  defp guardian_module, do: camel_app_name() <> ".Auth.Guardian"

  defp repo_module, do: camel_app_name() <> ".Repo"

  defp secret_key_base, do: Input.escape(Rand.string())

  defp guardian_secret_key, do: Input.escape(Rand.string())

  defp expose_graphiql, do: Input.ask_yN("Expose graphiql endpoint")

  defp db_name, do: Input.read_string("DB name")

  defp db_user, do: Input.read_string("DB username")

  defp db_pass, do: Input.read_string("DB password")

  defp db_host, do: Input.read_string("DB hostname", "localhost")

  defp db_port, do: Input.read_integer("DB port", 5432)

  @shortdoc "Generates config/env.secret.exs"
  def run([]), do: run(["dev"])

  def run([environment]) do
    if environment not in ["dev", "test", "prod"] do
      Mix.raise("""
      mix app.gen.secret must be called with `dev`, `test` or `prod`
      """)
    end

    file_name = "config/#{environment}.secret.exs"

    file_content =
      EEx.eval_file("config/template.secret.eex",
        app_name: app_name(),
        secret_key_base: secret_key_base(),
        router_module: router_module(),
        endpoint_module: endpoint_module(),
        guardian_module: guardian_module(),
        guardian_secret_key: guardian_secret_key(),
        repo_module: repo_module(),
        expose_graphiql: expose_graphiql(),
        db_name: db_name(),
        db_user: db_user(),
        db_pass: db_pass(),
        db_host: db_host(),
        db_port: db_port()
      )

    case File.write(file_name, file_content) do
      :ok ->
        Mix.shell().info("#{file_name} successfully generated")

      {:error, _} ->
        Mix.raise("Unable to create #{file_name}")
    end
  end
end

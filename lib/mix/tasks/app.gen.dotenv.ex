defmodule Mix.Tasks.App.Gen.Dotenv do
  use Mix.Task

  alias Hitbit.Utils.Input
  alias Hitbit.Utils.Rand

  defp secret_key_base, do: Input.escape(Rand.string())

  defp guardian_secret_key, do: Input.escape(Rand.string())

  defp db_name, do: Input.read_string("DB name")

  defp db_user, do: Input.read_string("DB username")

  defp db_pass, do: Input.read_string("DB password")

  defp db_host, do: Input.read_string("DB hostname")

  defp db_port, do: Input.read_integer("DB port", 5432)

  @shortdoc "Generates .env"
  def run([]) do
    file_name = ".env"

    file_content =
      EEx.eval_file("config/template.dotenv.eex",
        secret_key_base: secret_key_base(),
        guardian_secret_key: guardian_secret_key(),
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

import Config

config :hitbit,
  ecto_repos: [Hitbit.Repo]

# Configures the endpoint
config :hitbit, HitbitWeb.Endpoint,
  http: [port: 4000],
  url: [host: "localhost", port: 4000],
  pubsub: [name: Hitbit.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian configuration
config :hitbit, Hitbit.Guardian, issuer: "hitbit"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

file_exists? = fn path ->
  path
  |> Path.expand(__DIR__)
  |> File.exists?()
end

if file_exists?.("#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end

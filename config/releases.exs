import Config

port = System.get_env("PORT", "4000")

# Configures the endpoint
config :hitbit, HitbitWeb.Endpoint,
  http: [port: port],
  url: [host: "localhost", port: port]

import Config

Code.require_file("rand.ex", "lib/hitbit/utils")

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hitbit, HitBitWeb.Endpoint,
  secret_key_base: HitBit.Utils.Rand.string(),
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Database configuration
config :hitbit, HitBit.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: System.get_env("DB_NAME", "postgres"),
  username: System.get_env("DB_USER", "postgres"),
  password: System.get_env("DB_PASS", "postgres"),
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432"),
  pool_size: 15

# Guardian configuration
config :hitbit, HitBit.Guardian, secret_key: HitBit.Utils.Rand.string()

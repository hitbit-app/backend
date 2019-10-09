defmodule HitBit.Repo do
  use Ecto.Repo,
    otp_app: :hitbit,
    adapter: Ecto.Adapters.Postgres
end

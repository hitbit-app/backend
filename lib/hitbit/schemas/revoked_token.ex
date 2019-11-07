defmodule Hitbit.Schemas.RevokedToken do
  use Ecto.Schema

  @primary_key {:jti, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "revoked_tokens" do
    timestamps(updated_at: false)
  end
end

defmodule Hitbit.Repo.Migrations.RevokedTokens do
  use Ecto.Migration

  def change do
    create table(:revoked_tokens, primary_key: false) do
      add :jti, :uuid, primary_key: true

      timestamps(updated_at: false)
    end
  end
end

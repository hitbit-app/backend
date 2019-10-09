defmodule HitBit.Repo.Migrations.Init do
  use Ecto.Migration

  def up do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :username, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :groups, {:array, :string}, null: false

      add :avatar_url, :string
      add :ear_points, :integer, null: false, default: 0
      add :voice_points, :integer, null: false, default: 0

      timestamps()
    end

    create unique_index(
             :users,
             [:username],
             name: :users_username_index
           )

    create unique_index(
             :users,
             [:email],
             name: :users_email_index
           )

    create table(:posts, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :audio_url, :string, null: false

      add :author_user_id, references(:users, type: :uuid), null: false

      timestamps()
    end

    create unique_index(
             :posts,
             [:audio_url],
             name: :posts_audio_url_index
           )

    execute("CREATE TYPE comment_type AS ENUM ('REGULAR', 'REPLY', 'ANSWER')")
    execute("CREATE TYPE vote_type AS ENUM ('UP', 'DOWN')")

    create table(:post_votes, primary_key: false) do
      add :user_id,
          references(:users, type: :uuid, on_delete: :delete_all),
          primary_key: true

      add :post_id,
          references(:posts, type: :uuid, on_delete: :delete_all),
          primary_key: true

      add :type, :vote_type, null: false
    end

    create table(:comments, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :text, :text, null: false
      add :type, :comment_type, null: false, default: "REGULAR"

      add :post_id, references(:posts, type: :uuid), null: false
      add :author_user_id, references(:users, type: :uuid), null: false
      add :parent_comment_id, references(:comments, type: :uuid)

      timestamps()
    end

    create table(:comment_votes, primary_key: false) do
      add :user_id,
          references(:users, type: :uuid, on_delete: :delete_all),
          primary_key: true

      add :comment_id,
          references(:comments, type: :uuid, on_delete: :delete_all),
          primary_key: true

      add :type, :vote_type, null: false
    end
  end
end

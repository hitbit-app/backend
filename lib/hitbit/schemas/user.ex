defmodule Hitbit.Schemas.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias Hitbit.Schemas.{Post, Comment, PostVote, CommentVote}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @required_fields [
    :username,
    :email,
    :password_hash
  ]

  @optional_fields [
    :groups,
    :avatar_url,
    :ear_points,
    :voice_points
  ]

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :groups, {:array, :string}, default: []

    field :avatar_url, Hitbit.Ecto.URL
    field :ear_points, :integer
    field :voice_points, :integer

    has_many :posts, Post, foreign_key: :author_user_id
    has_many :comments, Comment, foreign_key: :author_user_id
    has_many :post_votes, PostVote, foreign_key: :user_id
    has_many :comment_votes, CommentVote, foreign_key: :user_id

    timestamps()
  end

  def changeset(%__MODULE__{} = user, %{password: pass} = attrs) do
    hash = Hitbit.Auth.hash(pass)

    attrs =
      attrs
      |> Map.delete(:password)
      |> Map.put(:password_hash, hash)

    changeset(user, attrs)
  end

  def changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:username, name: :users_username_index)
    |> unique_constraint(:email, name: :users_email_index)
  end

  def data do
    Dataloader.Ecto.new(Hitbit.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end
end

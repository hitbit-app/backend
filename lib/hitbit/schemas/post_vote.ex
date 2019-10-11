defmodule Hitbit.Schemas.PostVote do
  use Ecto.Schema

  import Ecto.Changeset

  alias Hitbit.Schemas.{User, Post}

  @foreign_key_type :binary_id

  @primary_key false
  schema "post_votes" do
    field :type, :string

    belongs_to :user, User, primary_key: true
    belongs_to :post, Post, primary_key: true
  end

  def changeset(%__MODULE__{} = vote, attrs) do
    vote
    |> cast(attrs, [:type])
  end
end

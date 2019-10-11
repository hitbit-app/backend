defmodule Hitbit.Schemas.Comment do
  use Ecto.Schema

  import Ecto.Changeset

  alias Hitbit.Schemas.{User, Post, CommentVote}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "comments" do
    field :text, :string
    field :type, :string

    belongs_to :post, Post
    belongs_to :author, User, foreign_key: :author_user_id
    belongs_to :parent, __MODULE__, foreign_key: :parent_comment_id
    has_many :replies, __MODULE__, foreign_key: :parent_comment_id
    has_many :votes, CommentVote, foreign_key: :comment_id

    timestamps()
  end

  def changeset(%__MODULE__{} = comment, attrs) do
    comment
    |> cast(attrs, [:text, :type])
  end

  def data do
    Dataloader.Ecto.new(Hitbit.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end
end

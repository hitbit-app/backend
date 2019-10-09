defmodule HitBit.Schemas.Post do
  use Ecto.Schema

  import Ecto.Changeset

  alias HitBit.Schemas.{User, Comment, PostVote}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "posts" do
    field :audio_url, HitBit.Ecto.URL

    belongs_to :author, User, foreign_key: :author_user_id
    has_many :comments, Comment, foreign_key: :post_id
    has_many :votes, PostVote, foreign_key: :post_id

    timestamps()
  end

  def changeset(%__MODULE__{} = post, attrs) do
    post
    |> cast(attrs, [:audio_url])
  end

  def data do
    Dataloader.Ecto.new(HitBit.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end
end

defmodule GraphQL.Types.Comment do
  use Absinthe.Schema.Notation

  import Ecto.Query

  import Absinthe.Resolution.Helpers,
    only: [dataloader: 1, batch: 3]

  alias Hitbit.Repo
  alias Hitbit.Schemas.{User, Comment, CommentVote}

  def batch_user_votes(user_id, comment_ids) do
    from(v in CommentVote,
      select: %{
        c_id: v.comment_id,
        type: v.type
      },
      where:
        v.user_id == ^user_id and
          v.comment_id in ^comment_ids
    )
    |> Repo.all()
    |> Map.new(&{&1.c_id, &1.type |> String.downcase() |> String.to_atom()})
  end

  def batch_comment_replies(_, comment_ids) do
    from(comment in Comment,
      where:
        comment.parent_comment_id in ^comment_ids and
          comment.type == "REPLY"
    )
    |> Repo.all()
    |> Map.new(&{&1.id, &1})
  end

  def batch_comment_votes(_, comment_ids) do
    from(v in CommentVote,
      select: %{
        comment_id: v.comment_id,
        up: fragment("count(CASE WHEN type = 'UP' THEN 1 END)"),
        down: fragment("count(CASE WHEN type = 'DOWN' THEN 1 END)")
      },
      where: v.comment_id in ^comment_ids,
      group_by: v.comment_id
    )
    |> Repo.all()
    |> Map.new(&{&1.comment_id, Map.delete(&1, :comment_id)})
  end

  def resolve_user_vote(%Comment{id: c_id}, _, %{context: %{user_id: u_id}}) do
    batch({__MODULE__, :batch_user_votes, u_id}, c_id, fn batch_results ->
      {:ok, Map.get(batch_results, c_id)}
    end)
  end

  def resolve_user_vote(%Comment{}, _, _), do: {:ok, nil}

  def resolve_comment_reply(%Comment{id: c_id}, _, _) do
    batch({__MODULE__, :batch_comment_replies}, c_id, fn batch_results ->
      {:ok, Map.get(batch_results, c_id)}
    end)
  end

  def resolve_comment_votes(%Comment{id: c_id}, _, _) do
    batch({__MODULE__, :batch_comment_votes}, c_id, fn batch_results ->
      {:ok, Map.get(batch_results, c_id, %{up: 0, down: 0})}
    end)
  end

  object :reply do
    field :id, non_null(:uuid)
    field :text, non_null(:string)

    field :user_vote,
          :vote,
          resolve: &resolve_user_vote/3

    field :author,
          :user,
          resolve: dataloader(User)

    field :votes,
          :up_down_votes,
          resolve: &resolve_comment_votes/3
  end

  object :comment do
    field :id, non_null(:uuid)

    field :text, non_null(:string)

    field :user_vote,
          :vote,
          resolve: &resolve_user_vote/3

    field :author,
          :user,
          resolve: dataloader(User)

    field :replies,
          list_of(:reply),
          resolve: &resolve_comment_reply/3

    field :votes,
          :up_down_votes,
          resolve: &resolve_comment_votes/3
  end
end

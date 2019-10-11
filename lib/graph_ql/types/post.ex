defmodule GraphQL.Types.Post do
  use Absinthe.Schema.Notation

  import Ecto.Query

  import Absinthe.Resolution.Helpers,
    only: [dataloader: 1, batch: 3]

  alias Hitbit.Repo
  alias Hitbit.Schemas.{User, Post, Comment, PostVote}

  def batch_user_votes(user_id, post_ids) do
    from(v in PostVote,
      select: %{
        p_id: v.post_id,
        type: v.type
      },
      where:
        v.user_id == ^user_id and
          v.post_id in ^post_ids
    )
    |> Repo.all()
    |> Map.new(&{&1.p_id, &1.type |> String.downcase() |> String.to_atom()})
  end

  def batch_post_answer(_, post_ids) do
    from(comment in Comment,
      where:
        comment.post_id in ^post_ids and
          comment.type == "ANSWER"
    )
    |> Repo.all()
    |> Map.new(&{&1.post_id, &1})
  end

  def batch_post_comments(_, post_ids) do
    from(comment in Comment,
      where:
        comment.post_id in ^post_ids and
          comment.type == "REGULAR"
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn comm, acc ->
      Map.update(acc, comm.post_id, [comm], &[comm | &1])
    end)
  end

  def batch_post_votes(_, post_ids) do
    from(v in PostVote,
      select: %{
        post_id: v.post_id,
        up: fragment("count(CASE WHEN type = 'UP' THEN 1 END)"),
        down: fragment("count(CASE WHEN type = 'DOWN' THEN 1 END)")
      },
      where: v.post_id in ^post_ids,
      group_by: v.post_id
    )
    |> Repo.all()
    |> Map.new(&{&1.post_id, Map.delete(&1, :post_id)})
  end

  def resolve_user_vote(%Post{id: p_id}, _, %{context: %{user_id: u_id}}) do
    batch({__MODULE__, :batch_user_votes, u_id}, p_id, fn batch_results ->
      {:ok, Map.get(batch_results, p_id)}
    end)
  end

  def resolve_user_vote(%Post{}, _, _), do: {:ok, nil}

  def resolve_post_answer(%Post{id: p_id}, _, _) do
    batch({__MODULE__, :batch_post_answer}, p_id, fn batch_results ->
      {:ok, Map.get(batch_results, p_id)}
    end)
  end

  def resolve_post_comments(%Post{id: p_id}, _, _) do
    batch({__MODULE__, :batch_post_comments}, p_id, fn batch_results ->
      {:ok, Map.get(batch_results, p_id)}
    end)
  end

  def resolve_post_votes(%Post{id: p_id}, _, _) do
    batch({__MODULE__, :batch_post_votes}, p_id, fn batch_results ->
      {:ok, Map.get(batch_results, p_id, %{up: 0, down: 0})}
    end)
  end

  object :post do
    field :id, non_null(:uuid)
    field :audio_url, non_null(:string)
    field :inserted_at, non_null(:string)

    field :user_vote,
          :vote,
          resolve: &resolve_user_vote/3

    field :author,
          :user,
          resolve: dataloader(User)

    field :answer,
          :comment,
          resolve: &resolve_post_answer/3

    field :comments,
          list_of(:comment),
          resolve: &resolve_post_comments/3

    field :votes,
          :up_down_votes,
          resolve: &resolve_post_votes/3
  end
end

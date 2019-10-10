defmodule GraphQL.Resolvers.User do
  use GraphQL.AuthResolver,
    include: :default_validation

  import Ecto.Query

  alias HitBit.Repo
  alias HitBit.Ecto.Helper
  alias HitBit.Schemas.{User, Post, Comment}
  alias HitBit.Schemas.{PostVote, CommentVote}

  defauth get_user_info(_data, %{context: ctx}) do
    case Repo.get(User, ctx.user_id) do
      nil -> {:error, :no_such_user}
      user -> {:ok, user}
    end
  end

  defp do_edit_user(data, user_id) do
    User
    |> Repo.get!(user_id)
    |> User.changeset(data)
    |> Repo.update()
    |> Helper.bool_resolver()
  end

  defauth edit_user(data, %{context: ctx}) do
    try do
      fn -> do_edit_user(data, ctx.user_id) end
      |> Repo.transaction()
      |> Helper.transaction_resolver()
    rescue
      _ in Ecto.NoResultsError -> {:error, :no_such_user}
    end
  end

  defauth insert_post(data, %{context: ctx}) do
    # TODO: upload size limit
    # TODO: audio validation

    # IO.inspect(data)
    # %{
    #   audio_file: %Plug.Upload{
    #     content_type: "application/octet-stream",
    #     filename: "<filename>",
    #     path: "/tmp/plug-1570/multipart-1570699493-939398894133130-3"
    #   }
    # }

    try do
      %Post{author_user_id: ctx.user_id}
      |> Post.changeset(%{audio_url: data.audio_url})
      |> Repo.insert()
      |> Helper.id_resolver()
    rescue
      e in Ecto.ConstraintError -> {:error, "#{e.constraint} violation"}
    end
  end

  defp do_edit_post(data, user_id) do
    post =
      from(p in Post,
        where:
          p.id == ^data.id and
            p.author_user_id == ^user_id
      )
      |> Repo.one!()

    post
    |> Post.changeset(data)
    |> Repo.update()
    |> Helper.bool_resolver()
  end

  defauth edit_post(data, %{context: ctx}) do
    try do
      fn -> do_edit_post(data, ctx.user_id) end
      |> Repo.transaction()
      |> Helper.transaction_resolver()
    rescue
      _ in Ecto.NoResultsError -> {:error, :no_such_post}
    end
  end

  defauth remove_post(data, %{context: ctx}) do
    from(p in Post,
      where:
        p.id == ^data.id and
          p.author_user_id == ^ctx.user_id
    )
    |> Repo.delete_all()
    |> case do
      {1, nil} -> {:ok, true}
      _ -> {:error, :no_such_post}
    end
  end

  defauth insert_comment(data, %{context: ctx}) do
    %Comment{
      text: data.text,
      type: "REGULAR",
      post_id: data.post_id,
      author_user_id: ctx.user_id
    }
    |> Repo.insert()
    |> Helper.id_resolver()
  end

  defp do_insert_reply(data, user_id) do
    parent_comment =
      from(c in Comment,
        where:
          c.id == ^data.comment_id and
            c.type == "REGULAR"
      )
      |> Repo.one!()

    %Comment{
      type: "REPLY",
      parent_comment_id: parent_comment.id,
      author_user_id: user_id,
      post_id: parent_comment.post_id
    }
    |> Comment.changeset(%{text: data.text})
    |> Repo.insert()
    |> Helper.id_resolver()
  end

  defauth insert_reply(data, %{context: ctx}) do
    try do
      fn -> do_insert_reply(data, ctx.user_id) end
      |> Repo.transaction()
      |> Helper.transaction_resolver()
    rescue
      _ in Ecto.NoResultsError -> {:error, :no_such_comment}
    end
  end

  defp do_accept_answer(data, user_id) do
    answer =
      from(c in Comment,
        join: p in Post,
        where:
          c.post_id == p.id and
            c.id == ^data.comment_id and
            p.author_user_id == ^user_id and
            c.type == "REGULAR"
      )
      |> Repo.one!()

    from(c in Comment,
      where:
        c.post_id == ^answer.post_id and
          c.type == "ANSWER"
    )
    |> Repo.update_all(set: [type: "REGULAR"])

    answer
    |> Comment.changeset(%{type: "ANSWER"})
    |> Repo.update()
    |> Helper.bool_resolver()
  end

  defauth accept_answer(data, %{context: ctx}) do
    try do
      fn -> do_accept_answer(data, ctx.user_id) end
      |> Repo.transaction()
      |> Helper.transaction_resolver()
    rescue
      _ in Ecto.NoResultsError -> {:error, :no_such_comment}
    end
  end

  defp do_vote_post(data, user_id, type) do
    try do
      %PostVote{
        post_id: data.post_id,
        user_id: user_id,
        type: type
      }
      |> Repo.insert(
        on_conflict: [set: [type: type]],
        conflict_target: [:post_id, :user_id]
      )
      |> Helper.bool_resolver()
    rescue
      _ in Ecto.ConstraintError -> {:error, :no_such_post}
    end
  end

  defp remove_vote_post(data, user_id) do
    from(v in PostVote,
      where:
        v.post_id == ^data.post_id and
          v.user_id == ^user_id
    )
    |> Repo.delete_all()
    |> case do
      {0, _} -> {:error, :no_such_vote}
      _ -> {:ok, true}
    end
  end

  defauth vote_post(data, %{context: ctx}) do
    case data.mode do
      :up -> do_vote_post(data, ctx.user_id, "UP")
      :down -> do_vote_post(data, ctx.user_id, "DOWN")
      :remove -> remove_vote_post(data, ctx.user_id)
    end
  end

  defp do_vote_comment(data, user_id, type) do
    try do
      %CommentVote{
        comment_id: data.comment_id,
        user_id: user_id,
        type: type
      }
      |> Repo.insert(
        on_conflict: [set: [type: type]],
        conflict_target: [:comment_id, :user_id]
      )
      |> Helper.bool_resolver()
    rescue
      _ in Ecto.ConstraintError -> {:error, :no_such_comment}
    end
  end

  defp remove_vote_comment(data, user_id) do
    from(v in CommentVote,
      where:
        v.comment_id == ^data.comment_id and
          v.user_id == ^user_id
    )
    |> Repo.delete_all()
    |> case do
      {0, _} -> {:error, :no_such_vote}
      _ -> {:ok, true}
    end
  end

  defauth vote_comment(data, %{context: ctx}) do
    case data.mode do
      :up -> do_vote_comment(data, ctx.user_id, "UP")
      :down -> do_vote_comment(data, ctx.user_id, "DOWN")
      :remove -> remove_vote_comment(data, ctx.user_id)
    end
  end
end

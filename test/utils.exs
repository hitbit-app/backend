defmodule Utils do
  alias HitBit.Repo
  alias HitBit.Schemas.{User, Post, Comment}

  def utc_now do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end

  def create_user(data) do
    user =
      %User{}
      |> User.changeset(data)
      |> Repo.insert!()

    Map.put(data, :id, user.id)
  end

  def create_post(data) do
    %Post{author_user_id: data.author.id}
    |> Post.changeset(%{audio_url: data.url})
    |> Repo.insert!()
  end

  def create_comment(data) do
    %Comment{
      post_id: data.post.id,
      author_user_id: data.author.id
    }
    |> Comment.changeset(%{text: data.text})
    |> Repo.insert!()
  end

  def create_default_user do
    user_data =
      create_user(%{
        username: "def-user",
        email: "def-user@hitbit.app",
        password: "def-user-password"
      })

    [user: user_data]
  end
end

# Script for populating the database. You can run it as:
#
#   mix run priv/repo/faker.exs

import Hitbit.Repo, only: [insert!: 1, insert_all: 2]

alias Hitbit.Schemas.{User, Post, Comment, PostVote, CommentVote}

require Logger

users = 20
posts_per_user = 8
comments_per_post = 4
replies_per_comment = 3

post_votes_per_user = 100
comment_votes_per_user = 100

users_in_db = Hitbit.Repo.aggregate(User, :count, :id)

if users_in_db >= users do
  Logger.info("Database seems alredy seeded with #{users_in_db} users")
  exit(:shutdown)
end

many = fn data, how_many, create_fn ->
  if how_many > 0 do
    Enum.reduce(1..how_many, data, fn _idx, acc -> create_fn.(acc) end)
  else
    data
  end
end

create_reply = fn %{replies: replies, users: users} = data, comment, post ->
  reply =
    %Comment{
      text: Faker.StarWars.quote(),
      type: "REPLY",
      post_id: post.id,
      parent_comment_id: comment.id,
      author_user_id: Enum.random(users).id
    }
    |> insert!()

  %{data | replies: [reply | replies]}
end

create_comment = fn %{users: users, comments: comments} = data, post ->
  comment =
    %Comment{
      text: Faker.StarWars.quote(),
      type: "REGULAR",
      post_id: post.id,
      author_user_id: Enum.random(users).id
    }
    |> insert!()

  %{data | comments: [comment | comments]}
  |> many.(replies_per_comment, fn data ->
    create_reply.(data, comment, post)
  end)
end

create_answer = fn %{users: users, comments: comments} = data, post ->
  comment =
    %Comment{
      text: Faker.StarWars.quote(),
      type: "ANSWER",
      post_id: post.id,
      author_user_id: Enum.random(users).id
    }
    |> insert!()

  %{data | comments: [comment | comments]}
  |> many.(replies_per_comment, fn data ->
    create_reply.(data, comment, post)
  end)
end

create_post = fn %{posts: posts} = data, user ->
  post =
    %Post{
      audio_url: Faker.Internet.url() <> "/" <> Ecto.UUID.generate(),
      author_user_id: user.id
    }
    |> insert!()

  %{data | posts: [post | posts]}
  |> many.(comments_per_post, fn data -> create_comment.(data, post) end)
  |> many.(:rand.uniform(2) - 1, fn data -> create_answer.(data, post) end)
end

add_user_meta = fn data, user ->
  post_votes =
    data.posts
    |> Enum.take_random(post_votes_per_user)
    |> Enum.map(
      &%{
        post_id: &1.id,
        user_id: user.id,
        type: if(:rand.uniform(2) > 1, do: "UP", else: "DOWN")
      }
    )

  comment_votes =
    data.comments
    |> Enum.take_random(comment_votes_per_user)
    |> Enum.map(
      &%{
        comment_id: &1.id,
        user_id: user.id,
        type: if(:rand.uniform(2) > 1, do: "UP", else: "DOWN")
      }
    )

  insert_all(PostVote, post_votes)
  insert_all(CommentVote, comment_votes)

  data
end

create_user = fn %{users: users} = data ->
  user =
    %User{}
    |> User.changeset(%{
      username: Faker.Name.name(),
      email: Faker.Internet.free_email(),
      password: "1234",
      avatar_url: Faker.Avatar.image_url(),
      ear_points: Faker.Random.Elixir.random_between(0, 100),
      voice_points: Faker.Random.Elixir.random_between(0, 100)
    })
    |> insert!()

  %{data | users: [user | users]}
  |> many.(posts_per_user, fn data -> create_post.(data, user) end)
  |> add_user_meta.(user)
end

%{
  users: [],
  posts: [],
  comments: [],
  replies: []
}
|> many.(users, create_user)

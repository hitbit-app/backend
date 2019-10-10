defmodule GraphQL.Schema do
  use Absinthe.Schema

  alias GraphQL.Resolvers
  alias HitBit.Schemas.{User, Post, Comment}

  import_types(GraphQL.Types.UUID)
  import_types(GraphQL.Types.User)
  import_types(GraphQL.Types.Post)
  import_types(GraphQL.Types.Comment)
  import_types(Absinthe.Plug.Types)

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(User, User.data())
      |> Dataloader.add_source(Post, Post.data())
      |> Dataloader.add_source(Comment, Comment.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def public_id_resolver(queryable) do
    fn %{id: id}, _resolution ->
      case HitBit.Repo.get(queryable, id) do
        nil ->
          {:error, "#{queryable} with ID #{id} not found"}

        res ->
          {:ok, res}
      end
    end
  end

  @desc "A vote can be an upvote (UP) or a downvote (DOWN)"
  enum :vote do
    value(:up)
    value(:down)
  end

  @desc "Vote mode: upvote, downvote or remove a vote from an item"
  enum :vote_mode do
    value(:up)
    value(:down)
    value(:remove)
  end

  @desc "How many upvotes and downvotes has an item"
  object :up_down_votes do
    field :up, :integer
    field :down, :integer
  end

  mutation do
    @desc "public: Creates new user"
    field :sign_up, :uuid do
      arg(:username, type: non_null(:string))
      arg(:email, type: non_null(:string))
      arg(:password, type: non_null(:string))

      resolve(&Resolvers.Public.sign_up/2)
    end

    @desc "public: Gives a token for bearer authentication"
    field :login, :string do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(&Resolvers.Public.authenticate/2)
    end

    @desc "user: Edits user info"
    field :edit_user, :boolean do
      arg(:username, type: :string)
      arg(:email, type: :string)
      arg(:avatar_url, type: :string)

      resolve(&Resolvers.User.edit_user/2)
    end

    @desc "user: Creates new post"
    field :insert_post, :uuid do
      arg(:audio_file, non_null(:upload))

      resolve(&Resolvers.User.insert_post/2)
    end

    @desc "user: Edits a post"
    field :edit_post, :boolean do
      arg(:id, non_null(:uuid))
      arg(:audio_url, :string)

      resolve(&Resolvers.User.edit_post/2)
    end

    @desc "user: Removes a post"
    field :remove_post, :boolean do
      arg(:id, non_null(:uuid))

      resolve(&Resolvers.User.remove_post/2)
    end

    @desc "user: Creates new comment"
    field :insert_comment, :uuid do
      arg(:text, non_null(:string))
      arg(:post_id, non_null(:uuid))

      resolve(&Resolvers.User.insert_comment/2)
    end

    @desc "user: Creates new comment to comment"
    field :insert_reply, :uuid do
      arg(:text, non_null(:string))
      arg(:comment_id, non_null(:uuid))

      resolve(&Resolvers.User.insert_reply/2)
    end

    @desc "user: Labels a comment as answer"
    field :accept_answer, :boolean do
      arg(:comment_id, non_null(:uuid))

      resolve(&Resolvers.User.accept_answer/2)
    end

    @desc "user: Upvote/downvote or remove vote from a post"
    field :vote_post, :boolean do
      arg(:mode, non_null(:vote_mode))
      arg(:post_id, non_null(:uuid))

      resolve(&Resolvers.User.vote_post/2)
    end

    @desc "user: Upvote/downvote or remove vote from a comment"
    field :vote_comment, :boolean do
      arg(:mode, non_null(:vote_mode))
      arg(:comment_id, non_null(:uuid))

      resolve(&Resolvers.User.vote_comment/2)
    end
  end

  query do
    @desc "public: UUID to post"
    field :post, :post do
      arg(:id, type: non_null(:uuid))

      resolve(public_id_resolver(Post))
    end

    @desc "public: UUID to comment"
    field :comment, :comment do
      arg(:id, type: non_null(:uuid))

      resolve(public_id_resolver(Comment))
    end

    @desc "public: Latest inserted posts (not just current user's)"
    field :latest_posts, list_of(:post) do
      arg(:limit, type: :integer, default_value: 15)

      resolve(&Resolvers.Public.latest_posts/2)
    end

    @desc "user: Gives back the authenticated user"
    field :user_info, :user do
      resolve(&Resolvers.User.get_user_info/2)
    end

    @desc "admin: The given key is a substring of username or email"
    field :search_users, list_of(:user) do
      arg(:key, type: non_null(:string))

      resolve(&Resolvers.Admin.search_users/2)
    end
  end
end

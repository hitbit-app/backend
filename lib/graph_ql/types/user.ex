defmodule GraphQL.Types.User do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Hitbit.Schemas.Post

  object :user do
    field :id, non_null(:uuid)
    field :username, non_null(:string)
    field :email, non_null(:string)
    field :avatar_url, :string
    field :ear_points, non_null(:integer)
    field :voice_points, non_null(:integer)

    field :posts,
          list_of(:post),
          resolve: dataloader(Post)
  end
end

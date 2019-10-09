defmodule HitBitWeb.Router do
  use HitBitWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/session-container", HitBitWeb do
    pipe_through :browser

    get "/", SessionController, :index
  end

  Application.get_env(:hitbit, __MODULE__, [])
  |> Keyword.get(:graphiql, false)
  |> if do
    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: GraphQL.Schema,
      json_codec: Jason,
      # :advanced :simple :playground
      interface: :playground,
      default_url: "/"
  end

  scope "/" do
    pipe_through :api

    forward "/", Absinthe.Plug,
      schema: GraphQL.Schema,
      json_codec: Jason
  end
end

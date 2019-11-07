defmodule Hitbit.Plug.AbsintheAuthContext do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, resource} <- Hitbit.Auth.decode_access_token(token) do
      %{user_id: resource.id, user_groups: resource.groups}
    else
      _ -> %{}
    end
  end
end

defmodule Hitbit.Plug.AbsintheAuthContext do
  @behaviour Plug

  alias Hitbit.Auth

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    with {:ok, token} <- Auth.get_header_token(conn),
         {:ok, resource} <- Auth.decode_access_token(token) do
      %{user_id: resource.id, user_groups: resource.groups}
    else
      _ -> %{}
    end
  end
end

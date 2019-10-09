defmodule GraphQL.AuthResolver do
  defmodule ContextValidation do
    @callback auth_ctx?(map) :: boolean
    @callback auth_error :: String.Chars.t()
  end

  defmacro __using__(opts) do
    to_include =
      opts
      |> Keyword.get_values(:include)
      |> Enum.map(&apply(__MODULE__, &1, []))

    quote do
      import unquote(__MODULE__)

      @behaviour ContextValidation

      unquote(to_include)
    end
  end

  def default_validation do
    quote do
      @impl ContextValidation
      def auth_ctx?(%{user_id: id}) when byte_size(id) > 0, do: true
      def auth_ctx?(_), do: false

      @impl ContextValidation
      def auth_error, do: :unauthorized
    end
  end

  def admin_validation do
    quote do
      @impl ContextValidation
      def auth_ctx?(%{user_id: id, user_groups: groups}),
        do: byte_size(id) > 0 and "admin" in groups

      def auth_ctx?(_), do: false

      @impl ContextValidation
      def auth_error, do: :unauthorized
    end
  end

  defp impl_suffix, do: "__impl"

  defp wrong_resolver_arg_num(n),
    do: raise("An absinthe resolver must have two or three args, #{n} given")

  defmacro defauth({name, meta, args}, body) do
    impl_name = String.to_atom(Atom.to_string(name) <> impl_suffix())
    impl_head = {impl_name, meta, args}

    fun_args =
      case length(args) do
        3 -> [:parent, :data, :resolution]
        2 -> [:data, :resolution]
        n -> wrong_resolver_arg_num(n)
      end
      |> Enum.map(&Macro.var(&1, nil))

    quote do
      def unquote({name, [], fun_args}) do
        with %{context: ctx} <- unquote(Macro.var(:resolution, nil)),
             true <- auth_ctx?(ctx) do
          unquote({impl_name, [], fun_args})
        else
          _ -> {:error, auth_error()}
        end
      end

      defp unquote(impl_head), unquote(body)
    end
  end
end

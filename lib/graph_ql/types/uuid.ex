defmodule GraphQL.Types.UUID do
  use Absinthe.Schema.Notation

  scalar :uuid,
    name: "UUID",
    description: """
    String representation as specified in RFC 4122.\n
    E.g.: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
    """ do
    serialize(& &1)

    parse(fn %{value: id} -> Ecto.UUID.cast(id) end)
  end
end

[
  import_deps: [:ecto, :phoenix],
  inputs: [
    "*.{ex,exs}",
    "priv/*/seeds.exs",
    "{config,lib}/**/*.{ex,exs}"
  ],
  subdirectories: [
    "rel",
    "test",
    "priv/*/migrations"
  ],
  line_length: 80
]

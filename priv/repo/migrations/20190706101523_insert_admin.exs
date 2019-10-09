defmodule HitBit.Repo.Migrations.InsertAdmin do
  use Ecto.Migration

  alias HitBit.Schemas.User
  alias HitBit.Repo

  def up do
    %User{}
    |> User.changeset(%{
      username: "Bob",
      email: "emiliano.bovetti@gmail.com",
      password_hash:
        "$argon2id$v=19$m=131072,t=8,p=4$JYteEEzbSXdZnlTEnBPOTA$QFCbX4yDb9n8u1ZzEY2HXSmUj7QioTh5GY8AI8evWGI",
      groups: ["admin"]
    })
    |> Repo.insert()
  end

  def down do
    import Ecto.Query

    from(u in User,
      where: u.email == "emiliano.bovetti@gmail.com"
    )
    |> Repo.delete_all()
  end
end

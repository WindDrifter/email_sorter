defmodule EmailSorter.Repo.Migrations.CreateUsersTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :full_name, :string, null: false
      add :oauth_token, :string, null: false
      add :oauth_refresh_token, :string
      add :oauth_token_expiration, :integer
      add :oauth_id_token, :string
      timestamps()
    end

    create unique_index(:users, [:email])
  end
end

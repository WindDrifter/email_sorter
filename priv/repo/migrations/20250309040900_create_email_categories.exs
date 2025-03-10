defmodule EmailSorter.Repo.Migrations.CreateEmailCategories do
  use Ecto.Migration

  def change do
    create table(:email_categories) do
      add :name, :string, null: false
      add :description, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:email_categories, [:name])
  end
end

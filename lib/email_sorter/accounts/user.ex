defmodule EmailSorter.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string, null: false
    field :full_name, :string, null: false
    field :oauth_token, :string, null: false
    field :oauth_refresh_token, :string
    field :oauth_token_expiration, :integer
    field :oauth_id_token, :string

    timestamps(type: :utc_datetime)
  end
  @required [
    :full_name,
    :oauth_token,
    :email
  ]
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end
end

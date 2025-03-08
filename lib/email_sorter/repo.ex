defmodule EmailSorter.Repo do
  use Ecto.Repo,
    otp_app: :email_sorter,
    adapter: Ecto.Adapters.Postgres
end

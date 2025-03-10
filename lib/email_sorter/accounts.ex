defmodule EmailSorter.Accounts do
  alias EmailSorter.Accounts.User
  alias EmailSorter.Repo

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end
end

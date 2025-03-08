defmodule EmailSorterWeb.GoogleAuthController do
  use EmailSorterWeb, :controller

  @doc """
  `index/2` handles the callback from Google Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, EmailSorterWeb.Endpoint.url())
    {:ok, profile} = ElixirAuthGoogle.get_user_profile(token.access_token)
    conn
    |> put_view(EmailSorterWeb.PageView)
    |> render(:welcome, profile: profile)
  end
end
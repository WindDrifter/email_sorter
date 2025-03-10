defmodule EmailSorter.TokenProvider do
  @callback fetch(String.t()) :: {:ok, %{token: String.t()}} | {:error, any()}
end

defmodule EmailSorter.GothTokenProvider do
  @behaviour EmailSorter.TokenProvider

  @impl true
  def fetch(scope) do
    case Goth.Token.fetch(scope) do
      {:ok, token} -> {:ok, %{token: token.token}}
      error -> error
    end
  end
end

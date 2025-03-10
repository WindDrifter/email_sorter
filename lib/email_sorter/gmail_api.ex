defmodule EmailSorter.GmailAPI do
  @callback gmail_users_messages_list(any(), String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  @callback gmail_users_messages_get(any(), String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  @callback gmail_users_messages_modify(any(), String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  @callback gmail_users_labels_create(any(), String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  @callback gmail_users_labels_list(any(), String.t()) :: {:ok, map()} | {:error, any()}
end

defmodule EmailSorter.GmailAPIImpl do
  @behaviour EmailSorter.GmailAPI

  alias GoogleApi.Gmail.V1.Api.Users

  @impl true
  def gmail_users_messages_list(conn, user_id, opts) do
    Users.gmail_users_messages_list(conn, user_id, opts)
  end

  @impl true
  def gmail_users_messages_get(conn, user_id, id, opts) do
    Users.gmail_users_messages_get(conn, user_id, id, opts)
  end

  @impl true
  def gmail_users_messages_modify(conn, user_id, id, opts) do
    Users.gmail_users_messages_modify(conn, user_id, id, opts)
  end

  @impl true
  def gmail_users_labels_create(conn, user_id, opts) do
    Users.gmail_users_labels_create(conn, user_id, opts)
  end

  @impl true
  def gmail_users_labels_list(conn, user_id) do
    Users.gmail_users_labels_list(conn, user_id)
  end
end

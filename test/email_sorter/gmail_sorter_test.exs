defmodule EmailSorter.GmailSorterTest do
  use ExUnit.Case, async: true
  import Mox
  require Logger

  # Setup mocks
  setup :verify_on_exit!

  # Mock the external services
  setup do
    # Mock token provider
    stub(TokenProviderMock, :fetch, fn _scope ->
      {:ok, %{token: "fake_token"}}
    end)

    # Mock ML operations
    stub(MLProviderMock, :load_model, fn {:hf, _model_name} ->
      {:ok, %{}}
    end)

    stub(MLProviderMock, :load_tokenizer, fn {:hf, _model_name} ->
      {:ok, %{}}
    end)

    stub(MLProviderMock, :text_classification, fn _model, _tokenizer, _opts ->
      %{}
    end)

    :ok
  end



  describe "process_emails/1" do


    test "processes unread messages" do
      messages = [
        %{id: "msg1"},
        %{id: "msg2"}
      ]

      # Mock Gmail API responses
      expect(GmailAPIMock, :gmail_users_messages_list, fn _conn, "me", _opts ->
        {:ok, %{messages: messages}}
      end)

      # Mock label creation
      expect(GmailAPIMock, :gmail_users_labels_create, 6, fn _conn, "me", _opts ->
        {:ok, %{id: "label_id"}}
      end)

      # Mock message retrieval
      expect(GmailAPIMock, :gmail_users_messages_get, 2, fn _conn, "me", msg_id, _opts ->
        {:ok, %{
          payload: %{
            headers: [
              %{name: "Subject", value: "Test Subject #{msg_id}"}
            ],
            body: %{
              data: Base.encode64("Test body #{msg_id}")
            }
          }
        }}
      end)

      # Mock label listing
      expect(GmailAPIMock, :gmail_users_labels_list, 2, fn _conn, "me" ->
        {:ok, %{
          labels: [
            %{name: "Important", id: "label1"},
            %{name: "Work", id: "label2"}
          ]
        }}
      end)

      # Mock message modification
      expect(GmailAPIMock, :gmail_users_messages_modify, 2, fn _conn, "me", _msg_id, _opts ->
        {:ok, %{}}
      end)

      # Mock Nx.Serving for predictions
      stub(Nx.Serving, :run, fn _model, _text ->
        {:ok, %{predictions: "Important"}}
      end)

      assert :ok = EmailSorter.GmailSorter.process_emails(10)
    end
  end

  describe "error handling" do

    test "handles Gmail API errors gracefully" do
      # Mock Gmail API error
      expect(GmailAPIMock, :gmail_users_messages_list, fn _conn, "me", _opts ->
        {:error, %{status: 500, body: "Internal Server Error"}}
      end)

      # Expect label creation attempts
      expect(GmailAPIMock, :gmail_users_labels_create, 6, fn _conn, "me", _opts ->
        {:ok, %{id: "label_id"}}
      end)

      assert_raise RuntimeError, fn ->
        EmailSorter.GmailSorter.process_emails(10)
      end
    end
  end
end

defmodule EmailSorter.GmailSorter do
  use GenServer
  require Logger

  @categories ["Important", "Work", "Personal", "Promotions", "Updates", "Social"]

  # Module configuration for better testability
  @token_provider Application.compile_env(:email_sorter, :token_provider, EmailSorter.GothTokenProvider)
  @ml_provider Application.compile_env(:email_sorter, :ml_provider, EmailSorter.BumblebeeProvider)
  @gmail_api Application.compile_env(:email_sorter, :gmail_api, EmailSorter.GmailAPIImpl)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, model} = load_model()
    {:ok, %{model: model}}
  end

  def process_emails(max_results \\ 50) do
    GenServer.cast(__MODULE__, {:process_emails, max_results})
  end

  def handle_cast({:process_emails, max_results}, state) do
    create_labels()
    process_unread_emails(max_results)
    {:noreply, state}
  end

  defp load_model do
    {:ok, model} = @ml_provider.load_model({:hf, "fathyshalaby/emailclassifier"})
    {:ok, tokenizer} = @ml_provider.load_tokenizer({:hf, "fathyshalaby/emailclassifier"})

    serving = @ml_provider.text_classification(
      model,
      tokenizer,
      compile: [batch_size: 1, sequence_length: 512],
      defn_options: [compiler: EXLA]
    )

    {:ok, serving}
  end

  defp create_labels do
    conn = get_gmail_connection()

    Enum.each(@categories, fn category ->
      try do
        @gmail_api.gmail_users_labels_create(
          conn,
          "me",
          body: %{name: category}
        )
      rescue
        _ -> :ok  # Label might already exist
      end
    end)
  end

  defp process_unread_emails(max_results) do
    conn = get_gmail_connection()

    case @gmail_api.gmail_users_messages_list(
      conn,
      "me",
      labelIds: ["UNREAD"],
      maxResults: max_results
    ) do
      {:ok, response} ->
        case response.messages do
          nil -> Logger.info("No unread messages found")
          messages -> Enum.each(messages, &process_message(&1, conn))
        end
      {:error, error} ->
        raise "Failed to fetch messages: #{inspect(error)}"
    end
  end

  defp process_message(message, conn) do
    {:ok, msg} = @gmail_api.gmail_users_messages_get(
      conn,
      "me",
      message.id,
      format: "full"
    )

    {subject, body} = extract_content(msg)
    category = classify_email(subject, body)

    label_id = get_label_id(category, conn)

    {:ok, _} = @gmail_api.gmail_users_messages_modify(
      conn,
      "me",
      message.id,
      body: %{addLabelIds: [label_id]}
    )

    Logger.info("Processed email: #{subject} -> #{category}")
  end

  defp extract_content(msg) do
    headers = msg.payload.headers
    subject =
      Enum.find_value(headers, "", fn
        %{name: "Subject", value: value} -> value
        _ -> nil
      end)

    body =
      case msg.payload do
        %{parts: parts} when is_list(parts) ->
          Enum.find_value(parts, "", fn
            %{mimeType: "text/plain", body: %{data: data}} -> Base.url_decode64!(data)
            _ -> nil
          end)
        %{body: %{data: data}} ->
          Base.url_decode64!(data)
        _ -> ""
      end

    {subject, body}
  end

  defp classify_email(subject, body) do
    text = "#{subject} #{body}"
    {:ok, prediction} = Nx.Serving.run(get_model(), text)
    prediction.predictions
  end

  defp get_label_id(label_name, conn) do
    {:ok, response} = @gmail_api.gmail_users_labels_list(conn, "me")

    Enum.find_value(response.labels, fn label ->
      if label.name == label_name, do: label.id
    end)
  end

  defp get_gmail_connection do
    {:ok, token} = @token_provider.fetch("https://www.googleapis.com/auth/gmail.modify")
    GoogleApi.Gmail.V1.Connection.new(token.token)
  end

  defp get_model do
    GenServer.call(__MODULE__, :get_model)
  end

  def handle_call(:get_model, _from, %{model: model} = state) do
    {:reply, model, state}
  end
end

ExUnit.start()

# Define mocks
Mox.defmock(TokenProviderMock, for: EmailSorter.TokenProvider)
Mox.defmock(MLProviderMock, for: EmailSorter.MLProvider)
Mox.defmock(GmailAPIMock, for: EmailSorter.GmailAPI)

# Set up application config for test environment
Application.put_env(:email_sorter, :token_provider, TokenProviderMock)
Application.put_env(:email_sorter, :ml_provider, MLProviderMock)
Application.put_env(:email_sorter, :gmail_api, GmailAPIMock)

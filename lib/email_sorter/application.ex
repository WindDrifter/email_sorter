defmodule EmailSorter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EmailSorterWeb.Telemetry,
      EmailSorter.Repo,
      {DNSCluster, query: Application.get_env(:email_sorter, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EmailSorter.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: EmailSorter.Finch},
      # Start the Gmail Sorter
      # {EmailSorter.GmailSorter, []},
      # Start to serve requests, typically the last entry
      EmailSorterWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EmailSorter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EmailSorterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

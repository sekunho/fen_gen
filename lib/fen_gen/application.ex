defmodule FenGen.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: FenGen.Worker,
      size: 2,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FenGenWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: FenGen.PubSub},
      # Start the Endpoint (http/https)
      FenGenWeb.Endpoint,
      :poolboy.child_spec(:worker, poolboy_config())
      # Start a worker by calling: FenGen.Worker.start_link(arg)
      # {FenGen.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FenGen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FenGenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

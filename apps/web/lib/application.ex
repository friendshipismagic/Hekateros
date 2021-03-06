defmodule Web.Application do
  use Application
  require Prometheus.Registry
  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    Web.PhoenixInstrumenter.setup()
    Web.PipelineInstrumenter.setup()
    Web.MetricsExporter.setup()
    Prometheus.Registry.register_collector(:prometheus_process_collector)


    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Web.Endpoint, []),
      # Start your own worker by calling: Web.Worker.start_link(arg1, arg2, arg3)
      # worker(Web.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Web.Supervisor]
    Logger.info(IO.ANSI.green <> "Web application started!" <> IO.ANSI.reset())
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end
end


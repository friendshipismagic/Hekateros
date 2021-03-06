defmodule IRC.ConnectionHandler do
  use GenServer
  require Logger
  alias IRC.State

  def start_link(%State{}=state) do
    GenServer.start_link __MODULE__, state, name: __MODULE__
  end

  def init(state) do
    ExIRC.Client.add_handler(state.client, self())
    if state.ssl? do
      ExIRC.Client.connect_ssl!(state.client, state.host, state.port)
    else
      ExIRC.Client.connect!(state.client, state.host, state.port)
    end
    Logger.info(IO.ANSI.green() <> "IRC Application started!" <> IO.ANSI.reset())
    {:ok, state}
  end

  def handle_info({:connected, _server, _port}, state) do
    Logger.info(IO.ANSI.green() <> "Establishing connection to #{state.host}" <> IO.ANSI.reset())
    
    ExIRC.Client.logon state.client, state.pass, state.nick, state.user, state.name
    {:noreply, state}
  end


  def handle_info({:unrecognized, _code, msg, _sender}, state) do
    Logger.debug(msg.args)
    {:noreply, state}
  end

  def handle_info({:notice, msg, _sender}, state) do
    Logger.debug(msg)
    {:noreply, state}
  end

  def handle_info(:disconnected, _state) do
    Logger.debug "Disconnected from server"
    {:noreply, nil}
  end

  def handle_info(:logged_in, state) do
    Logger.info(IO.ANSI.green() <> "Logged in!" <> IO.ANSI.reset())
    Logger.debug "Joining " <> Enum.join(state.channels, ", ")
    case state.channels do
      [] -> nil
       _ -> Enum.each(state.channels, &ExIRC.Client.join(state.client, &1))
    end
    {:noreply, state}
  end

  def handle_info({:whois, %ExIRC.Whois{}=whois}, state) do
    Agent.update(IRC.WhoisHandler, fn buffer -> Map.put(buffer, whois.nick, whois) end)
    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.debug "[Message] #{inspect(message)}"
    {:noreply, state}
  end

  def handle_call(:dump, _from, state) do
    Logger.info (inspect state)
    {:reply, state, state}
  end

  def handle_call(:client, _from, state) do
    {:reply, state.client, state}
  end

  def terminate(reason, state) do
    Logger.info "[TERMINATE] #{inspect(reason)}"
    ExIRC.Client.stop!(state.client)
    reason
  end
end

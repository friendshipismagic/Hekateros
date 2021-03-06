defmodule IRC.ChannelHandler do

  alias IRC.State
  require Logger
  alias Core.{Chan,Link}
  import IRC.Helpers, only: [get_whois: 1]
  use GenServer

  def start_link(%State{}=state) do
    GenServer.start_link(__MODULE__, state.client, name: __MODULE__)
  end

  def init(client) do
    ExIRC.Client.add_handler(client, self())
    {:ok, client}
  end

  def handle_info({:invited, sender, chan}, client=state) do
    ExIRC.Client.whois(client, sender.nick)
    user = get_whois(sender.nick)
    if user.account_name == nil do
      ExIRC.Client.msg(client, :privmsg, sender.nick, "Sorry, you don't seem to be registered to NickServ. I can't let you administrate Hecateros on #{chan}.")
    else
      Chan.create_chan(%{name: chan, slug: Link.create_slug()})
      ExIRC.Client.join(client, chan)
      case Core.Users.check_admin(user, chan) do
        {:ok, :admin} ->
          nil
        {:error, :noadmin} ->
          send_banner(client, user.nick)
          Core.Users.add_admin(chan, user)
      end
    end
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp send_banner(client, nick) do

    banner = 
             Path.join(:code.priv_dir(:irc), "new_chan_admin.txt")
             |> File.read!
             |> String.replace("\n\n", "\n \n")
             |> String.split("\n")

    Enum.each(banner, fn msg ->
      ExIRC.Client.msg(client, :privmsg, nick, msg)
    end)
  end
end

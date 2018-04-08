defmodule IRC.LinksHandler do

  alias IRC.{State, Helpers}
  alias Core.Repo
  use GenServer
  require Logger

  def start_link(%State{}=state) do
    GenServer.start_link(__MODULE__, state.client, name: __MODULE__)
  end

  def init(client) do
    ExIRC.Client.add_handler(client, self())
    {:ok, client}
  end

  def handle_info({:received, message, _sender, chan}, state) do
    message
    |> parse(chan)
    |> insert

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def parse(message, chan) do
    channel        =  String.downcase(chan)
    with {:ok, url}         <- parse_url(message),
         {:ok, taglist}     <- parse_tags(message),
         {:ok, :ok}         <- check_filters(url, taglist, channel),
         {:ok, title, desc} <- Helpers.get_info(url) do
           {:ok, %{tags: taglist, url: url, chan: channel, title: title, description: desc}}
    else
      e -> e
    end
  end

  def insert({:error, _}), do: nil
  def insert({:ok, map}) do
    Core.insert_link(map)
  end

  def parse_tags(message) do
    tags_regex = ~r/(?<=\#)(.*?)(?=\#)/
    case Regex.run(tags_regex, message, capture: :first) do
      nil    -> {:error, :notag}
      [tags] ->
        taglist =
          tags
          |> String.replace(" ", "")
          |> String.split(",")
          |> Enum.map(fn tag -> String.downcase tag end)

        {:ok, taglist}
    end
  end


  def parse_url(message) do
    url_regex = ~r/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[.\!\/\\w]*))?)/iu
    case Regex.run(url_regex, message, capture: :first) do
      nil   -> {:error, :nolink}
      [url] -> url |> String.split("#") |> hd |> validate_url
    end
  end

  defp validate_url(url) do
    case URI.parse(url) do
      %URI{scheme: nil} -> {:error, :invalid}
      %URI{host: nil, path: nil} -> {:error, :invalid}
      _ -> {:ok, url}
    end
  end

  def check_filters(url, taglist, channel_name) do
    chan = Repo.get_by(Chan, name: channel_name)
    t = with true <- chan.settings.has_tag_filter?,
             :ok  <- is_in_filters([tags: taglist, chan: chan]) do
              :ok
        else
          :filtered -> :filtered
          false     -> :ok
        end

    u = with true <- chan.settings.has_url_filter?,
             :ok  <- is_in_filters([url: url, chan: chan]) do
               :ok
        else
          :filtered -> :filtered
          false     -> :ok
        end
    {t, u}
  end

  def is_in_filters([url: url, chan: chan]) do
    if url in chan.settings.url_filters do
      :filtered
    else
      :ok
    end
  end

  def is_in_filters([tags: tags, chan: chan]) do
    if Enum.all?(tags, fn t -> t in chan.settings.tag_filters end) do
      :ok
    else
      :filtered
    end
  end
end

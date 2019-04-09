defmodule Web.CurrentPlayerCountView do
  use Phoenix.HTML
  use Phoenix.LiveView

  alias Grapevine.PlayerPresence

  def render(assigns) do
    ~L[
      <p>
        Join <%= @count %> other players.
      </p>
    ]
  end

  def mount(_session, socket) do
    Web.Endpoint.subscribe("player:presence")
    socket = assign(socket, :count, PlayerPresence.current_total_count())
    {:ok, socket}
  end

  def handle_info(broadcast = %Phoenix.Socket.Broadcast{topic: "player:presence"}, socket) do
    socket = assign(socket, :count, broadcast.payload.count)
    {:noreply, socket}
  end
end

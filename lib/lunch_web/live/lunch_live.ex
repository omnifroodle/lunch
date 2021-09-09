defmodule LunchWeb.LunchLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use Phoenix.LiveView

  def mount(_params, session, socket) do
    user = Map.get(session, "current_user")
    {:ok, assign(socket, user: user, lunchers: [])}
  end

  def handle_event("want_lunch", _values, socket) do
    lunch = %{
      name: socket.assigns.user.email,
      time: to_string(NaiveDateTime.to_iso8601(NaiveDateTime.utc_now) <> "Z"),
      location: "1",
      thumbnail: socket.assigns.user.picture.thumbnail
    }
    {:ok, _} = Astra.Rest.add_row("lunch", "lunchers", lunch)
    {:ok, lunchers} = Astra.Rest.search_table("lunch", "lunchers", %{location: %{"$eq": "1"}})
    {:noreply, assign(socket, lunchers: lunchers)}
  end
end

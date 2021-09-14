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
    reduced_lunchers = Enum.reduce(lunchers, %{}, fn (x, acc) ->
      if Map.has_key?(acc, x.name) do
        put_in(acc, [x.name, :count], get_in(acc, [x.name, :count]) + 1)
      else
        Map.put(acc, x.name, Map.put(x, :count, 1))
      end
    end)
    |> Map.to_list()
    |> Enum.sort_by(&(elem(&1, 1).count), :desc)
    {:noreply, assign(socket, lunchers: reduced_lunchers)}
  end

end

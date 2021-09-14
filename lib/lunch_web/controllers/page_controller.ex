defmodule LunchWeb.PageController do
  use LunchWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def fake(conn, _params) do
    user = Lunch.RandomUser.get()
    lunch = %{
      name: user.email,
      time: to_string(NaiveDateTime.to_iso8601(NaiveDateTime.utc_now) <> "Z"),
      location: "1",
      thumbnail: user.picture.thumbnail
    }
    {:ok, _} = Astra.Rest.add_row("lunch", "lunchers", lunch)
    render(conn, "index.html", luncher: lunch)
  end

end

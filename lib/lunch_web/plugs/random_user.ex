defmodule LunchWeb.Plugs.RandomUser do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if !get_session(conn, :current_user) do
      put_session(conn, :current_user, Lunch.RandomUser.get())
    else
      conn
    end
  end
end

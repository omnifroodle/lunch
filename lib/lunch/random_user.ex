defmodule Lunch.RandomUser do
  require Poison

  def get() do
    response = HTTPoison.get!("https://randomuser.me/api/")
    {:ok, result} = Poison.decode(response.body, %{keys: :atoms})
    [faker | _] = result.results
    faker
  end
end

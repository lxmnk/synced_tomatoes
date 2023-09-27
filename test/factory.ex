defmodule SyncedTomatoes.Factory do
  use ExMachina.Ecto, repo: SyncedTomatoes.Repos.Postgres

  alias SyncedTomatoes.Core.User

  def user_factory do
    %User{login: sequence("login_")}
  end
end

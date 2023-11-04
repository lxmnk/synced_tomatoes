defmodule SyncedTomatoes.Factory do
  use ExMachina.Ecto, repo: SyncedTomatoes.Repos.Postgres

  alias SyncedTomatoes.Core.{Settings, Token, User}

  def user_factory do
    %User{login: sequence("login_")}
  end

  def token_factory do
    %Token{value: sequence("secret_")}
  end

  def settings_factory do
    %Settings{}
  end
end

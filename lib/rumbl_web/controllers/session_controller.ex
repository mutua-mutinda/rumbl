defmodule RumblWeb.SessionController do
  @moduledoc false
  use RumblWeb, :controller

  alias Rumbl.Accounts.User
  alias Rumbl.Accounts

  def new(conn, _params) do
    changeset = Accounts.change_registration(%User{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"session" => %{"username" => username, "password" => pass}}) do
    case Rumbl.Accounts.authenticate_by_username_and_pass(username, pass) do
      {:ok, user} ->
        conn
        |> RumblWeb.Auth.login(user)
        |> put_flash(:info, "Welcome back #{user.username}!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "invalid username/password combination")
        |> render("new.html")

    end
  end

  def delete(conn, _params) do
    conn
    |> RumblWeb.Auth.logout()
    |> redirect(to: Routes.session_path(conn, :new))
  end
end

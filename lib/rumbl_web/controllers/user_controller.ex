defmodule RumblWeb.UserController do
  @moduledoc false

  use RumblWeb, :controller

  alias Rumbl.Accounts
  alias Rumbl.Accounts.User

  plug :authenticate when action in [:index, :edit, :show]

  def new(conn, _params) do
    changeset = Accounts.change_registration(%User{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> RumblWeb.Auth.login(user)
        |> put_flash(:info, "#{user.name} created!" )
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "ERR: PEBKAC!, you cant do that mate! ")
        |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)

  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)
    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "#{user.name} updated!" )
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        put_flash(conn, :error, "ERR: ID10T! what happened??")
        render(conn, "show.html", changeset: changeset)
    end
  end

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user(id)
    render(conn, "show.html", user: user)
  end

  defp authenticate(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to view this page")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end

  end

end

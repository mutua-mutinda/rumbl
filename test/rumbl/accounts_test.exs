defmodule Rumbl.AccountsTest do
  use Rumbl.DataCase, async: true

  alias Rumbl.Accounts
  alias Rumbl.Accounts.User

  describe "authenticate_by_username_or_pass/2" do
    @pass "1234"

    setup do
      {:ok, user: user_fixture(password: @pass)}
    end

    test "returns user with correct password", %{user: user} do
      assert {:ok, auth_user} = Accounts.authenticate_by_username_and_pass(user.username, @pass)

      assert auth_user.id == user.id
    end

    test "return unauthorized error with invalid password", %{user: user} do
      assert {:error, :unauthorized} = Accounts.authenticate_by_username_and_pass(user.username, "badpass")
    end

    test "return not found error with no matching user for email" do
      assert {:error, :not_found} = Accounts.authenticate_by_username_and_pass("unknownuser", @pass)
    end
  end

  describe "register_user/1" do
    @valid_attrs %{
      name: "User",
      username: "eva",
      password: "secret"
    }
    @invalid_attrs %{}

    test "with valid data inserts user" do
      assert {:ok, %User{id: id}=user} = Accounts.register_user(@valid_attrs)
      assert user.name == "User"
      assert user.username == "eva"
      assert [%User{id: ^id}] = Accounts.list_users()
    end

    test "with invalid data does not insert data" do
      assert {:error, _changeset} = Accounts.register_user(@invalid_attrs)
      assert Accounts.list_users() == []
    end

    test "enforces uniques usernames" do
      assert {:ok, %User{id: id}} = Accounts.register_user(@valid_attrs)
      assert {:error, changeset} = Accounts.register_user(@valid_attrs)

      assert %{username: ["has already been taken"]} = errors_on(changeset)

      assert [%User{id: ^id}] = Accounts.list_users()
    end

    test "does not accept long usernames" do
      attrs = Map.put(@valid_attrs, :username, String.duplicate("a", 30))
      {:error, changeset} = Accounts.register_user(attrs)

      assert %{username: ["should be at most 20 character(s)"]} = errors_on(changeset)
      assert Accounts.list_users() == []
    end

    test "requires password to be at least 4 chars long" do
      attrs = Map.put(@valid_attrs, :password, "123")
      {:error, changeset} = Accounts.register_user(attrs)

      assert %{password: ["should be at least 4 character(s)"]} = errors_on(changeset)
      assert Accounts.list_users() == []
    end
  end
end

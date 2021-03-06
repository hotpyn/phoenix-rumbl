defmodule Hello.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller
  alias Hello.Router.Helpers

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)

    cond do
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)
      user = user_id && repo.get(Hello.User, user_id) ->
        put_current_user(conn, user)
      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    # The step is extremely important and it protects us from session fixation attacks.
    # It tells Plug to send the session cookie back to the client with a different identifier, in case an attacker knew, by any chance, the previous one.
    |> configure_session(renew: true)
  end

  def login_by_user_name_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Hello.User, username: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        # When a user is not found, we use Comeonin’s dummy_checkpw() function to simulate a password check with variable timing.
        # This hardens our authentication layer against timing attacks which is crucial to keeping our application secure.
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def logout(conn)do
    # this prevents us from using put_flash in controller :(
    # configure_session(conn, drop: true)

    # If you want to keep the session around, you could also have deleted only the user id information by calling:
    delete_session(conn, :user_id)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page.")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end

  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end
end

defmodule Authit.Plug.Enforce do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _) do
    Plug.Conn.register_before_send(conn, fn new_conn ->
      if new_conn.assigns[:permissions_checked] do
        new_conn
      else
        conn
        |> send_resp(401, "")
      end
    end)
  end
end

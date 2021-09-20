defmodule Authit.DefaultResponseHandler do
  @behaviour Authit.ResponseHandler

  import Plug.Conn

  @impl true
  @spec forbidden(Plug.Conn.t()) :: Plug.Conn.t()
  def forbidden(conn) do
    resp(conn, 403, "{error: \"forbidden\"}")
  end

  @impl true
  @spec unauthorized(Plug.Conn.t()) :: Plug.Conn.t()
  def unauthorized(conn) do
    resp(conn, 401, "{error: \"unauthorized\"}")
  end
end

defmodule Authit.DefaultResponseHandler do
  @behaviour Authit.ResponseHandler

  import Plug.Conn

  @impl true
  @spec forbidden(Plug.Conn.t()) :: Plug.Conn.t()
  def forbidden(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> resp(403, "{\"error\": \"forbidden\"}")
  end

  @impl true
  @spec unauthorized(Plug.Conn.t()) :: Plug.Conn.t()
  def unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> resp(401, "{\"error\": \"unauthorized\"}")
  end

  @impl true
  @spec not_found(Plug.Conn.t()) :: Plug.Conn.t()
  def not_found(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> resp(404, "{\"error\": \"not_found\"}")
  end
end

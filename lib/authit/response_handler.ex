defmodule Authit.ResponseHandler do
  import Plug.Conn

  @callback forbidden(Plug.Conn.t()) :: Plug.Conn.t()
  @callback unauthorized(Plug.Conn.t()) :: Plug.Conn.t()

  @spec forbidden(module(), Plug.Conn.t()) :: Plug.Conn.t()
  def forbidden(impl, conn) do
    conn
    |> impl.forbidden()
    |> halt()
  end

  @spec forbidden(module(), Plug.Conn.t()) :: Plug.Conn.t()
  def unauthorized(impl, conn) do
    conn
    |> impl.unauthorized()
    |> halt()
  end
end

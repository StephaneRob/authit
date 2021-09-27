defmodule Authit.Plug.Enforce do
  alias Authit.ResponseHandler

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    Plug.Conn.register_before_send(conn, fn new_conn ->
      if new_conn.assigns[:permissions_checked] do
        new_conn
      else
        :authit
        |> Application.get_env(:response_handler, Authit.DefaultResponseHandler)
        |> ResponseHandler.unauthorized(conn)
      end
    end)
  end
end

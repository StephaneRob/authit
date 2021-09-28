defmodule Authit.Plug.EnforceTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "must register a before send call back" do
    conn = conn(:get, "/")
    conn = Authit.Plug.Enforce.call(conn, [])
    assert [before_send] = conn.before_send
    conn = before_send.(conn)
    assert conn.status == 401
    assert conn.resp_body == "{\"error\": \"unauthorized\"}"
  end
end

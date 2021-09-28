defmodule Authit.Plug.AuthorizeTest do
  use ExUnit.Case, async: true
  use Plug.Test

  describe "with invalid authorizer" do
    setup do
      options =
        Authit.Plug.Authorize.init(
          resource: Hello.Pages.Page,
          current_resource: :current_user
        )

      conn =
        :get
        |> conn("/")
        |> Plug.Conn.put_private(:phoenix_action, :show)
        |> Authit.Plug.Enforce.call([])

      {:ok, options: options, conn: conn}
    end

    test "authorize request", %{options: options, conn: conn} do
      assert_raise RuntimeError,
                   ~r/Invalid authorizer. Make sure to `use Authit.Authorizer`/,
                   fn ->
                     Authit.Plug.Authorize.call(conn, options)
                   end
    end
  end

  describe "with valid authorizer" do
    defmodule Hello.Pages.Page.Authorizer do
      use Authit.Authorizer

      can? _, _, :show, _, do: false
      can? _, _, :index, _, do: true

      can? _, _, :show_with_assigns, _ do
        {:ok, page: "Hello world"}
      end

      can? _, _, :show_with_not_found, _ do
        {:error, :not_found}
      end
    end

    setup ctx do
      options =
        Authit.Plug.Authorize.init(
          resource: Hello.Pages.Page,
          current_resource: :current_user
        )

      conn =
        :get
        |> conn("/")
        |> Plug.Conn.put_private(:phoenix_action, ctx[:action])
        |> Authit.Plug.Enforce.call([])

      {:ok, options: options, conn: conn}
    end

    @tag action: :show
    test "show return a 403", %{options: options, conn: conn} do
      refute conn.assigns[:permissions_checked]
      %{status: status, resp_body: resp_body} = conn = Authit.Plug.Authorize.call(conn, options)
      assert status == 403
      assert resp_body == "{\"error\": \"forbidden\"}"
      assert conn.assigns[:permissions_checked]
    end

    @tag action: :index
    test "index continue", %{options: options, conn: conn} do
      refute conn.assigns[:permissions_checked]
      %{status: status, resp_body: resp_body} = conn = Authit.Plug.Authorize.call(conn, options)
      refute status
      refute resp_body
      assert conn.assigns[:permissions_checked]
    end

    @tag action: :whatever
    test "whatever (undefined action) return 403", %{options: options, conn: conn} do
      refute conn.assigns[:permissions_checked]
      %{status: status, resp_body: resp_body} = conn = Authit.Plug.Authorize.call(conn, options)
      assert status == 403
      assert resp_body == "{\"error\": \"forbidden\"}"
      assert conn.assigns[:permissions_checked]
    end

    @tag action: :show_with_assigns
    test "show with assign continue and add assigns", %{options: options, conn: conn} do
      refute conn.assigns[:permissions_checked]
      %{status: status, resp_body: resp_body} = conn = Authit.Plug.Authorize.call(conn, options)
      refute status
      refute resp_body
      assert conn.assigns[:permissions_checked]
      assert conn.assigns[:page] == "Hello world"
    end

    @tag action: :show_with_not_found
    test "show with not found return 404", %{options: options, conn: conn} do
      refute conn.assigns[:permissions_checked]
      %{status: status, resp_body: resp_body} = conn = Authit.Plug.Authorize.call(conn, options)
      assert status == 404
      assert resp_body == "{\"error\": \"not_found\"}"
      assert conn.assigns[:permissions_checked]
    end
  end
end

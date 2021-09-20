defmodule Authit.Plug.Authorize do
  import Plug.Conn

  alias Authit.ResponseHandler

  defmodule Options do
    defstruct [
      :except,
      :authorization_module,
      :current_resource,
      :response_handler
    ]
  end

  def init(opts) do
    resource = Keyword.get(opts, :resource)

    authorization_module =
      opts
      |> Keyword.get(:authorization_module, authorization_module(resource))
      |> verify_module!()

    %Options{
      except: Keyword.get(opts, :except, []),
      authorization_module: authorization_module,
      current_resource: Keyword.get(opts, :current_resource, :current_user),
      response_handler: Keyword.get(opts, :response_handler)
    }
  end

  def call(conn, %Options{} = opts) do
    action = conn.private.phoenix_action
    params = conn.params

    # Either ways permissions has been checked (valid or not)
    conn = permissions_checked!(conn)

    if action not in opts.except do
      opts.authorization_module
      |> apply(:can?, [
        conn.assigns[opts.current_resource],
        action,
        params
      ])
      |> case do
        {:ok, assigns} ->
          conn
          |> merge_assigns(assigns)

        true ->
          conn

        _ ->
          opts
          |> response_handler()
          |> ResponseHandler.forbidden(conn)
      end
    end
  end

  defp authorization_module(resource) do
    Module.concat([resource, Authorizer])
  end

  defp verify_module!(module) do
    if not function_exported?(module, :valid_authit_authorizer?, 0) do
      raise """
      Invalid authorizer. Make sure to `use Authit.Authorizer`

      ```
      defmodule MyApp.Resource.Authorizer do
        use Authit.Authorizer

        can?(_, _, _, do: true)
      end
      ```
      """
    end

    module
  end

  defp permissions_checked!(conn) do
    assign(conn, :permissions_checked, true)
  end

  defp response_handler(%{response_handler: response_handler})
       when not is_nil(response_handler) do
    response_handler
  end

  defp response_handler(_) do
    Application.get_env(:authit, :response_handler, Authit.DefaultResponseHandler)
  end
end

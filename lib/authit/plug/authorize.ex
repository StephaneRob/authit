defmodule Authit.Plug.Authorize do
  import Plug.Conn

  defmodule Options do
    defstruct [:except, :authorization_module, :current_resource]
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
      current_resource: Keyword.get(opts, :current_resource, :current_user)
    }
  end

  def call(conn, %Options{} = opts) do
    action = conn.private.phoenix_action
    params = conn.params

    if action in opts.except do
      permissions_checked!(conn)
    else
      case apply(opts.authorization_module, :can?, [
             conn.assigns[opts.current_resource],
             action,
             params
           ]) do
        {:ok, assigns} ->
          conn
          |> merge_assigns(assigns)
          |> permissions_checked!()

        true ->
          permissions_checked!(conn)

        _ ->
          conn
          |> permissions_checked!()
          |> send_resp(403, "")
          |> halt()
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
end

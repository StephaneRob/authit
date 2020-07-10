defmodule Authit.Plug.Authorize do
  import Plug.Conn

  def init(opts) do
    resource = Keyword.fetch!(opts, :resource)
    current_resource = Keyword.get(opts, :current_resource, :current_user)
    except = Keyword.get(opts, :except, [])
    %{resource: resource, current_resource: current_resource, except: except}
  end

  def call(conn, %{resource: resource, current_resource: current_resource, except: except} = opts) do
    action = conn.private.phoenix_action
    params = conn.params

    authorization_module =
      Map.get(opts, :authorization_module, authorization_module(resource))
      |> verify_module!()

    if action in except do
      permission_checked!(conn)
    else
      case apply(authorization_module, :can?, [
             conn.assigns[current_resource],
             action,
             params
           ]) do
        {:ok, assigns} ->
          conn
          |> merge_assigns(assigns)
          |> permission_checked!()

        true ->
          permission_checked!(conn)

        _ ->
          conn
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
      Invalid authorizer. Make sure to `use Authit.Helper`

      ```
      defmodule MyApp.Resource.Authorizer do
        use Authit.Helper

        can?(_, _, _, do: true)
      end
      ```
      """
    end
  end

  defp permission_checked!(conn) do
    assign(conn, :permission_checked, true)
  end
end

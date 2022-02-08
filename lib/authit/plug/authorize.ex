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

    %Options{
      except: Keyword.get(opts, :except, []),
      authorization_module:
        Keyword.get(opts, :authorization_module, authorization_module(resource)),
      current_resource: Keyword.get(opts, :current_resource, :current_user),
      response_handler: Keyword.get(opts, :response_handler)
    }
  end

  def call(conn, %Options{} = opts) do
    action = conn.private.phoenix_action
    params = conn.params

    authorization_module = verify_module!(opts.authorization_module)
    Process.put(Authit.key(), true)

    if action in opts.except do
      conn
    else
      response =
        apply(authorization_module, :can?, [
          conn,
          conn.assigns[opts.current_resource],
          action,
          params
        ])

      case response do
        {:ok, assigns} ->
          conn
          |> merge_assigns(assigns)

        true ->
          conn

        error ->
          response_type = error_kind(error)
          handler = response_handler(opts)

          apply(ResponseHandler, response_type, [handler, conn])
      end
    end
  end

  defp error_kind({:error, :not_found}), do: :not_found
  defp error_kind(_), do: :forbidden

  defp authorization_module(resource) do
    Module.concat([resource, Authorizer])
  end

  defp verify_module!(module) do
    try do
      apply(module, :valid_authit_authorizer?, [])
      module
    rescue
      _ ->
        raise """
        Invalid authorizer. Make sure to `use Authit.Authorizer`

        ```
        defmodule MyApp.Resource.Authorizer do
          use Authit.Authorizer

          can?(_, _, _, _, do: true)
        end
        ```
        """
    end
  end

  defp response_handler(%{response_handler: response_handler})
       when not is_nil(response_handler) do
    response_handler
  end

  defp response_handler(_) do
    Application.get_env(:authit, :response_handler, Authit.DefaultResponseHandler)
  end
end

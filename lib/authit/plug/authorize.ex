defmodule Authit.Plug.Authorize do
  import Plug.Conn

  alias Authit.ResponseHandler

  defmodule Options do
    defstruct [
      :except,
      :authorizer,
      :current_resource,
      :response_handler
    ]
  end

  def init(opts) do
    %Options{
      except: Keyword.get(opts, :except, []),
      authorizer: Keyword.get(opts, :authorizer),
      current_resource: Keyword.get(opts, :current_resource, :current_user),
      response_handler: Keyword.get(opts, :response_handler)
    }
  end

  def call(conn, %Options{authorizer: authorizer} = opts) do
    action = conn.private.phoenix_action
    params = conn.params

    authorizer = verify_authorizer!(authorizer)

    # Either ways permissions has been checked (valid or not)
    conn = permissions_checked!(conn)

    if action in opts.except do
      conn
    else
      response =
        apply(authorizer, :can?, [
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

  defp verify_authorizer!(nil) do
    raise """
    Make sure to pass an authorization module to `Authit.Plug.Authorize`
    ```
    """
  end

  defp verify_authorizer!(module) do
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

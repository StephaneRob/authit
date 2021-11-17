defmodule Authit.Authorizer do
  defmacro __using__(_) do
    quote do
      import Authit.Authorizer
      @before_compile Authit.Authorizer

      def valid_authit_authorizer?, do: true
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def can?(_, _, _, _), do: false
    end
  end

  @spec can?(Plug.Conn.t(), map(), atom(), map(), any()) :: Macro.t()
  defmacro can?(conn, current_resource, action, params, do: block) do
    quote do
      def can?(unquote(conn), unquote(current_resource), unquote(action), unquote(params)) do
        unquote(block)
      end
    end
  end
end

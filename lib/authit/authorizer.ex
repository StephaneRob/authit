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

  defmacro can?(conn, role, action, params, do: block) do
    quote do
      def can?(unquote(conn), unquote(role), unquote(action), unquote(params)) do
        unquote(block)
      end
    end
  end
end

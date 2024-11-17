defmodule Authit.Authorizer do
  defmacro __using__(_) do
    quote do
      # import Authit.Authorizer
      @before_compile Authit.Authorizer
      @callback can?(Plug.Conn.t(), map(), atom(), map()) :: true | false

      def valid_authit_authorizer?, do: true
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def can?(_, _, _, _), do: false
    end
  end
end

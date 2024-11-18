defmodule Authit.Authorizer do
  @callback can?(
              conn :: Plug.Conn.t(),
              current_resource :: map(),
              action :: atom(),
              params :: map()
            ) :: true | false | {:ok, assigns :: keyword()}

  defmacro __using__(_) do
    quote do
      @behaviour Authit.Authorizer
      # import Authit.Authorizer
      @before_compile Authit.Authorizer

      def valid_authit_authorizer?, do: true
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def can?(_, _, _, _), do: false
    end
  end
end

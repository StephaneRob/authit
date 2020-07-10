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
      def can?(_, _, _), do: false
    end
  end

  # # FIXME:
  # # defmacro can?(_, _, _, do: _) do
  # #   raise """
  # #   Your rule has to contain a resource
  # #   ex: can?(@member_admin, _, %WhApi.Offices.Office{}, _, do: true)
  # #   """
  # # end

  defmacro can?(role, action, params, do: block) do
    quote do
      def can?(unquote(role), unquote(action), unquote(params)) do
        unquote(block)
      end
    end
  end
end

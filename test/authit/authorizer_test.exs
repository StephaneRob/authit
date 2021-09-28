defmodule Authit.AuthorizerTest do
  use ExUnit.Case, async: true

  defmodule Hello.Pages.Page.Authorizer do
    use Authit.Authorizer
  end

  test "Authorizer have default functions" do
    refute Hello.Pages.Page.Authorizer.can?("test", "test", "test", "test")
    assert Hello.Pages.Page.Authorizer.valid_authit_authorizer?()
  end
end

# Authit

Tiny authorization library for Phoenix application. (POC)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `authit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:authit, "~> 0.1.0"}
  ]
end
```

## Usage

**Authit** comes with 2 plugs:

- `Authit.Plug.Enforce`: Router plug, will verify that authorization has been check in controller before sending the response

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug :ensure_authenticated
    plug Authit.Plug.Enforce
  end

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index

    scope "/sensible" do
      pipe_through [:auth]
      ...
    end
  end

end
```

- `Authit.Plug.Authorize`: per controller plug, to check authorization for each action

```elixir
defmodule HelloWeb.PageController do
  use HelloWeb, :controller
  plug Authit.Plug.Authorize,
    resource: Hello.Pages.Page,
    current_resource: :current_user

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
```

In this controller `Authit.Plug.Authorize` will expect an `Hello.Pages.Page.Authorizer` module to check authorization with your own logic. An authorizer MUST `use Authit.Authorizer` to be valid.

```elixir
defmodule Hello.Pages.Page.Authorizer do
  use Authit.Authorizer
end
```

#### Not authorized by default

An emtpy authorizer like above, will reject all action and the authorize plug will send back a 403. To customize authorization you can define rule depending on 3 parameters: `current_user` (picked up in conn assigns), `action`(phoenix action) and `params`.

```elixir
defmodule Hello.Pages.Page.Authorizer do
  use Authit.Authorizer

  # allow show action for everybody
  can?(_, :show, _, do: true)


  # allow index action for admin user ony
  can?(current_user, :index, _, do: current_user.admin?)

  # allow only the author to delete a page
  can?(current_user, :delete, %{"id" => id}) do
    page = Hello.Pages.get(id)
    current_user.id == page.author_id
  end
end
```

#### Avoid load resource many times

To authorize request it's possible to return either `true` or `{:ok, assigns}`. In case you need to reuse already loaded resource in a can?/3 block you can return the resource in assigns and they will be merged in the conn.

```elixir
defmodule Hello.Pages.Page.Authorizer do
  use Authit.Authorizer
  # allow only the author to delete a page
  can?(current_user, :delete, %{"id" => id}) do
    page = Hello.Pages.get(id)
    if current_user.id == page.author_id do
      {:ok, page: page}
    else
      false
    end
  end
end
```

```elixir
defmodule HelloWeb.PageController do
  use HelloWeb, :controller
  plug Authit.Plug.Authorize,
    resource: Hello.Pages.Page,
    current_resource: :current_user

  def delete(conn, _params) do
    with page when not is_nil(page) <- conn.assigns[:page],
        Hello.Pages.delete_page(page) do
      ...
    end
  end
end
```

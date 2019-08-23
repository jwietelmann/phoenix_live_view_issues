defmodule LvtestWeb.Router do
  use LvtestWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LvtestWeb do
    pipe_through :browser
    live "/", TestLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", LvtestWeb do
  #   pipe_through :api
  # end
end

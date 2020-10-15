defmodule MycoBotUiWeb.Router do
  use MycoBotUiWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MycoBotUiWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MycoBotUiWeb do
    pipe_through :browser

    live "/", DashboardLive

    # TODO hide behind auth
    live_dashboard "/metrics", metrics: MycoBotUiWeb.Telemetry
  end

  # Other scopes may use custom stacks.
  # scope "/api", MycoBotUiWeb do
  #   pipe_through :api
  # end
end

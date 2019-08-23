defmodule LvtestWeb.PageController do
  use LvtestWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

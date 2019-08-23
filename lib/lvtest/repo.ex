defmodule Lvtest.Repo do
  use Ecto.Repo,
    otp_app: :lvtest,
    adapter: Ecto.Adapters.Postgres
end

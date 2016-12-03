defmodule Staging.Reservation do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  schema "reservations" do
    belongs_to :server, Staging.Server
    field :user_id
    field :start_date, Ecto.Date
    field :end_date, Ecto.Date
  end

  def active(query \\ __MODULE__) do
    from r in query,
    where: r.start_date <= ^Timex.today
    and r.end_date >= ^Timex.today
  end
end

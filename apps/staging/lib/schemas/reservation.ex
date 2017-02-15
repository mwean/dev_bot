defmodule Staging.Reservation do
  alias Staging.{Repo, Server}
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  schema "reservations" do
    belongs_to :server, Server
    field :user_id
    field :start_date, Ecto.Date
    field :end_date, Ecto.Date
  end

  def active(query \\ __MODULE__) do
    from r in query,
    where: r.start_date <= ^Staging.today
    and r.end_date >= ^Staging.today
  end

  # TODO: Change this when we switch to times for reservations
  def release!(reservation = %__MODULE__{end_date: end_date}) do
    case end_date do
      a -> Repo.delete!(reservation)
      _ ->
        yesterday = Timex.shift(Staging.today, days: -1)

        Ecto.Changeset.change(reservation, end_date: yesterday)
        |> Repo.update
    end
  end
end

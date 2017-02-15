defmodule Staging.Server do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]
  alias Staging.{Repo, Reservation}

  schema "servers" do
    field :name
    field :prod_data, :boolean, default: false
    has_many :reservations, Reservation
    has_one :active_reservation, Reservation
  end

  def with_active_reservation do
    active_reservations = Reservation.active
    from s in __MODULE__,
    preload: [active_reservation: ^active_reservations]
  end

  def order_by_name(query) do
    from s in query, order_by: s.name
  end

  def reserve(user_id: user_id, end_date: end_date) do
    non_prod_reservation = from s in available_for_reservation, where: s.prod_data == false, limit: 1

    case Repo.one(non_prod_reservation) do
      nil ->
        # TODO: Try with prod data
        :none_available
      server ->
        reserve!(server, user_id, end_date)
        {:ok, server}
    end
  end

  def reserve(server, user_id, end_date) do
    case available?(server) do
      true ->
        reserve!(server, user_id, end_date)
        :ok
      false -> :not_available
    end
  end

  def reserve!(server, user_id, end_date) do
    Repo.insert!(%Reservation{
      server: server,
      user_id: user_id,
      start_date: Ecto.Date.cast!(Staging.today),
      end_date: Ecto.Date.cast!(end_date)
    })
  end

  def release(server, user_id) do
    reservation = current_reservation(server)

    if reservation && reservation.user_id == user_id do
      Reservation.release!(reservation)
      :ok
    else
      :not_reserved
    end
  end

  def available?(server) do
    active_reservations_for_server(server)
    |> Repo.none?
  end

  def current_reservation(server) do
    active_reservations_for_server(server)
    |> Repo.one
  end

  defp active_reservations_for_server(server), do: Reservation.active(from r in Reservation, where: r.server_id == ^server.id)

  def available_for_reservation do
    from s in __MODULE__,
    left_join: r in Reservation,
    on: r.server_id == s.id
    and fragment("daterange(?, ?, '[]') @> ?", r.start_date, r.end_date, type(^Staging.today, Ecto.Date)),
    where: is_nil(r.id)
  end
end

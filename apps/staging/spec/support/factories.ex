defmodule Staging.Factory do
  use ExMachina.Ecto, repo: Staging.Repo

  def server_factory do
    %Staging.Server{
      name: sequence(:name, &("staging-#{&1}")),
      prod_data: false
    }
  end

  def reservation_factory do
    %Staging.Reservation{
      server: build(:server),
      user_id: "U1234ABCD",
      start_date: Ecto.Date.cast!(Timex.shift(Timex.today, days: -3)),
      end_date: Ecto.Date.cast!(Timex.shift(Timex.today, days: 3))
    }
  end
end

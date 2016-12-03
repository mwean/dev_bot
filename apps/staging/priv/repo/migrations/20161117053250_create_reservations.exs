defmodule Staging.Repo.Migrations.CreateReservations do
  use Ecto.Migration

  def change do
    create table(:reservations) do
      add :server_id, references(:servers)
      add :user_id, :string
      add :start_date, :date
      add :end_date, :date
    end
  end
end

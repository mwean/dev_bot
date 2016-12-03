defmodule Staging.Repo.Migrations.CreateServers do
  use Ecto.Migration

  def change do
    create table(:servers) do
      add :name, :string
      add :prod_data, :boolean, default: false, null: false
    end

    # create unique_index(:servers, [:name])
  end
end

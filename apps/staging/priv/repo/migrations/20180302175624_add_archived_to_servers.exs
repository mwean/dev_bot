defmodule Staging.Repo.Migrations.AddArchivedToServers do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add :archived, :bool, default: false, null: false
    end
  end
end

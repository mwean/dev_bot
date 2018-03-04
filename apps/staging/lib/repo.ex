defmodule Staging.Repo do
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :staging

  def init(_type, config) do
    case System.get_env("DATABASE_USERNAME") do
      nil -> {:ok, config}
      username -> {:ok, Keyword.put(config, :username, username)}
    end
  end

  def any?(model) do
    aggregate(model, :count, :id) > 0
  end

  def none?(query) do
    aggregate(query, :count, :id) == 0
  end

  def exists?(model, args) do
    length(all(from(m in model, where: ^args, select: m.id, limit: 1))) == 1
  end

  def pluck(model, field) do
    all(from(m in model, select: field(m, ^field)))
  end
end

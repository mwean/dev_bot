defmodule Staging.Repo do
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :staging

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

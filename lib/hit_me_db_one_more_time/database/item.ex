defmodule HitMeDbOneMoreTime.Database.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :name, :string
    field :description, :string
    field :created_at, :utc_datetime
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :description, :created_at])
    |> validate_required([:name, :description, :created_at])
  end
end

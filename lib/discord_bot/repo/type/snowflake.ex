defmodule DiscordBot.Repo.Type.Snowflake do
  require Nostrum.Snowflake
  use Ecto.Type

  def type(), do: :string

  def cast(term) do
    Nostrum.Snowflake.cast(term)
  end

  def dump(term) when Nostrum.Snowflake.is_snowflake(term) do
    {:ok, Nostrum.Snowflake.dump(term)}
  end

  def dump(term) do
    {:error, "#{inspect(term)} is not a valid snowflake"}
  end

  def load(term) do
    Nostrum.Snowflake.cast(term)
  end
end

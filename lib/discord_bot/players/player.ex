defmodule DiscordBot.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field(:name, :string)
    field(:display_name, :string)
    field(:group, :string)
    # TempleOSRS "Game mode" enumeration
    field(:game_mode, Ecto.Enum, values: [main: 0, im: 1, uim: 2, hcim: 3])
    # TempleOSRS "GIM" enumeration, 0 = not GIM, 22-25 = HCGIM
    field(:gim_mode, :integer)
    has_many(:deaths, DiscordBot.Players.Death)
    has_many(:former_memberships, DiscordBot.Players.FormerMembership)
  end

  def changeset(%__MODULE__{} = player, attrs) do
    player
    |> cast(attrs, [:name, :display_name, :group, :game_mode, :gim_mode])
    |> validate_required([:name, :display_name])
    |> unique_constraint(:name)
  end

  @doc """
  Game mode tag for display. Group members only show the group, so they get no tag.
  """
  @spec mode_tag(%__MODULE__{}) :: String.t() | nil
  def mode_tag(%__MODULE__{group: group}) when not is_nil(group), do: nil
  def mode_tag(%__MODULE__{gim_mode: gim_mode}) when gim_mode in 22..25, do: "HCGIM"
  def mode_tag(%__MODULE__{gim_mode: gim_mode}) when gim_mode not in [nil, 0], do: "GIM"
  def mode_tag(%__MODULE__{game_mode: :im}), do: "IM"
  def mode_tag(%__MODULE__{game_mode: :uim}), do: "UIM"
  def mode_tag(%__MODULE__{game_mode: :hcim}), do: "HCIM"
  def mode_tag(%__MODULE__{}), do: nil
end

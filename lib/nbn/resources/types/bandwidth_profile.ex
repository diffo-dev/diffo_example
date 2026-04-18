defmodule DiffoExample.Nbn.BandwidthProfile do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  BandwidthProfile type for NBN domain
  """

  require Ash.Type.NewType

  use Ash.Type.NewType,
    subtype_of: :atom,
    constraints: [one_of:  bandwidth_profiles()]

  def default do
    :home_fast
  end

  def bandwidth_profiles do
    [:D12_U1, :D25_U5, :D25_U10, :D50_U20, :D100_U40, :D250_U100, :D500_U200, :D1000_U400,
      :wireless_plus, :wireless_fast, :wireless_superfast,
      :home_fast, :home_superfast, :home_ultrafast, :home_hyperfast]
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule DiffoExample.Nbn.BandwidthProfile do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  BandwidthProfile type for NBN domain
  """

  use Ash.Type.Enum,
    values: [
      :D12_U1,
      :D25_U5,
      :D25_U10,
      :D50_U20,
      :D100_U40,
      :D250_U100,
      :D500_U200,
      :D1000_U400,
      :wireless_plus,
      :wireless_fast,
      :wireless_superfast,
      :home_fast,
      :home_superfast,
      :home_ultrafast,
      :home_hyperfast
    ]

  def default, do: :home_fast

  @doc """
  Returns the representative downstream rate (Mbps) for a bandwidth profile.

  CVCs are sold as symmetric capacity in this model — we ignore the asymmetry
  of satellite/wireless tiers and use the headline downstream figure as the
  bandwidth contribution when aggregating. Used by `CvcMetrics` to compute
  `avcs_total_bandwidth` across assigned AVCs.

  ## Examples

      iex> DiffoExample.Nbn.BandwidthProfile.downstream(:D100_U40)
      100
      iex> DiffoExample.Nbn.BandwidthProfile.downstream(:home_fast)
      500
  """
  def downstream(:D12_U1), do: 12
  def downstream(:D25_U5), do: 25
  def downstream(:D25_U10), do: 25
  def downstream(:D50_U20), do: 50
  def downstream(:D100_U40), do: 100
  def downstream(:D250_U100), do: 250
  def downstream(:D500_U200), do: 500
  def downstream(:D1000_U400), do: 1000
  def downstream(:wireless_plus), do: 100
  def downstream(:wireless_fast), do: 250
  def downstream(:wireless_superfast), do: 400
  def downstream(:home_fast), do: 500
  def downstream(:home_superfast), do: 750
  def downstream(:home_ultrafast), do: 1000
  def downstream(:home_hyperfast), do: 2000
  def downstream(nil), do: 0
end

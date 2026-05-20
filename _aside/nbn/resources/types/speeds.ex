# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule DiffoExample.Nbn.Speeds do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Speeds type for NBN domain
  """

  require Ash.Type.NewType
  alias DiffoExample.Nbn.Technology

  use Ash.Type.NewType,
    subtype_of: :tuple,
    constraints: [
      fields: [downstream: [type: :integer], upstream: [type: :integer]]
    ]

  def speeds do
    [
      {12, 1},
      {25, 5},
      {25, 10},
      {50, 20},
      {100, 40},
      {250, 100},
      {500, 200},
      {1000, 400},
      # :home_fast
      {500, 50},
      # :home_superfast
      {750, 50},
      # :home_ultrafast
      {1000, 100},
      # :home_hyperfast
      {2000, 100},
      {2000, 200},
      # :wireless_plus, :wireless_fast, :wireless_superfast
      {100, 20},
      {250, 20},
      {400, 40}
    ]
  end

  @impl true
  def cast_input(nil, _constraints), do: {:ok, nil}

  def cast_input(value, _constraints) when is_tuple(value) do
    if value in speeds() do
      {:ok, value}
    else
      {:error, "invalid downstream and upstream speed combination"}
    end
  end

  def cast_input({_value, _constraints}), do: {:error, "value must be a tuple"}

  defimpl Jason.Encoder do
    def encode(speeds, _opts) do
      Jason.OrderedObject.new(
        downstream: speeds.downstream,
        upstream: speeds.upstream,
        units: "Mbps"
      )
      |> Jason.encode!()
    end
  end

  @doc """
  Returns a tuple of maximum downstream and upstream speeds in Mbps
  given the bandwidth_profile and technology, or :error

  ## Examples
    iex> DiffoExample.Nbn.Speeds.speeds(:D12_U1, :Satellite)
    {12, 1}
    iex> DiffoExample.Nbn.Speeds.speeds(:home_fast, :FTTP)
    {500, 50}
    iex> DiffoExample.Nbn.Speeds.speeds(:home_hyperfast, :HFC)
    {2000, 100}
    iex> DiffoExample.Nbn.Speeds.speeds(:home_fast, :FixedWireless)
    :error
  """
  def speeds(:D12_U1, technology) when is_atom(technology) do
    if technology in Technology.values() do
      {12, 1}
    else
      :error
    end
  end

  def speeds(:D25_U5, technology) when is_atom(technology) do
    if technology in Technology.values() do
      {25, 5}
    else
      :error
    end
  end

  def speeds(:D25_U10, technology) when is_atom(technology) do
    if technology in [:FTTP, :HFC, :FTTC] do
      {25, 10}
    else
      :error
    end
  end

  def speeds(:D50_U20, technology) when is_atom(technology) do
    if technology in [:FTTP, :HFC, :FTTC] do
      {50, 20}
    else
      :error
    end
  end

  def speeds(bandwidth_profile, :FixedWireless) do
    case bandwidth_profile do
      :wireless_plus ->
        {100, 20}

      :wireless_fast ->
        {250, 20}

      :wireless_superfast ->
        {400, 40}

      _ ->
        :error
    end
  end

  def speeds(bandwidth_profile, :HFC) do
    case bandwidth_profile do
      :home_fast ->
        {500, 50}

      :home_superfast ->
        {750, 50}

      :home_ultrafast ->
        {1000, 100}

      :home_hyperfast ->
        {2000, 100}

      :U100_D40 ->
        {100, 40}

      _ ->
        :error
    end
  end

  def speeds(bandwidth_profile, :FTTP) do
    case bandwidth_profile do
      :home_fast ->
        {500, 50}

      :home_superfast ->
        {750, 50}

      :home_ultrafast ->
        {1000, 100}

      :home_hyperfast ->
        {2000, 200}

      :D100_U40 ->
        {100, 40}

      :D250_U100 ->
        {250, 100}

      :D500_200 ->
        {500, 200}

      :D1000_400 ->
        {1000, 400}

      _ ->
        :error
    end
  end

  def speeds(_bandwidth, _technology) do
    :error
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Util do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Util - various utilities for NBN domain
  """

  alias DiffoExample.Nbn.Technology

  @doc """
  Generates a new random NBN identifier with the prefix

  ## Examples
    iex> identifier = DiffoExample.Nbn.Util.identifier("AVC")
    iex> DiffoExample.Nbn.Util.identifier?(identifier)
    true

  """
  def identifier(prefix) when is_binary(prefix) and byte_size(prefix) == 3 do
    prefix <>
      (:rand.uniform(000_999_999_999)
       |> Integer.to_string()
       |> String.pad_leading(12, "0"))
  end

  @doc """
  Returns whether the identifier is a valid NBN identifier

  ## Examples
    iex> DiffoExample.Nbn.Util.identifier?("AVC120123456789")
    true
    iex> DiffoExample.Nbn.Util.identifier?("avc120123456789")
    false
  """
  def identifier?(identifier) when is_binary(identifier) do
    Regex.match?(~r/[A-Z]{3}\d{12}/, identifier)
  end

  @doc """
  Extracts a field value from a named item in a list

  ## Examples
    iex> DiffoExample.Nbn.Util.extract([%{name: :avc, value: %{cvlan: 1}}], :avc, :cvlan)
    1
  """
  def extract(items, name, field) when is_list(items) and is_atom(name) and is_atom(field) do
    Enum.reduce_while(items, nil, fn item, acc ->
      if name == item.name do
        if item.value != nil do
          {:halt, Map.get(item.value, field)}
        else
          {:halt, nil}
        end
      else
        {:cont, acc}
      end
    end)
  end

  @doc"""
  Returns a tuple of maximum downstream and upstream speeds in Mbps
  given the bandwidth_profile and technology, or :error

  ## Examples
    iex> DiffoExample.Nbn.Util.speeds(:D12_U1, :Satellite)
    {12, 1}
    iex> DiffoExample.Nbn.Util.speeds(:home_fast, :FTTP)
    {500, 50}
    iex> DiffoExample.Nbn.Util.speeds(:home_hyperfast, :HFC)
    {2000, 100}
    iex> DiffoExample.Nbn.Util.speeds(:home_fast, :FixedWireless)
    :error
  """
  def speeds(:D12_U1, technology) when is_atom(technology) do
    if technology in Technology.technology() do
      {12, 1}
    else
      :error
    end
  end

  def speeds(:D25_U5, technology) when is_atom(technology) do
    if technology in Technology.technology() do
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

  def speed(_bandwidth, _technology) do
    :error
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.CharacteristicChanges do
  @moduledoc """
  Shared changeset helpers for Access characteristic update actions.

  Characteristics store nested value structs (units, bandwidth profiles)
  as flat attributes. These helpers map the nested argument shape onto
  those attributes.
  """

  alias Ash.Changeset

  @doc """
  Splits a `%{amount: a, unit: u}` argument into two attributes.

  Returns the changeset unchanged when the argument is nil or not a map
  with both keys.
  """
  def set_unit(changeset, arg, amount_attr, unit_attr) do
    case Changeset.get_argument(changeset, arg) do
      %{amount: amount, unit: unit} ->
        changeset
        |> Changeset.force_change_attribute(amount_attr, amount)
        |> Changeset.force_change_attribute(unit_attr, unit)

      _ ->
        changeset
    end
  end

  @doc """
  Splits a `%{downstream: d, upstream: u, units: units}` bandwidth-profile
  argument into three attributes.

  Returns the changeset unchanged when the argument is nil or not a map
  with all three keys.
  """
  def set_bandwidth_profile(changeset, arg, downstream_attr, upstream_attr, units_attr) do
    case Changeset.get_argument(changeset, arg) do
      %{downstream: d, upstream: u, units: units} ->
        changeset
        |> Changeset.force_change_attribute(downstream_attr, d)
        |> Changeset.force_change_attribute(upstream_attr, u)
        |> Changeset.force_change_attribute(units_attr, units)

      _ ->
        changeset
    end
  end
end

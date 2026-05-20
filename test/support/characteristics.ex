# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Test.Characteristics do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Characteristics - Test support for Characteristics
  """
  import Outstand
  import ExUnit.Assertions

  @pool_names [:pairs, :ports, :slots, :cvlans, :svlans]

  @characteristic_modules %{
    cable: DiffoExample.Access.CableCharacteristic,
    card: DiffoExample.Access.CardCharacteristic,
    shelf: DiffoExample.Access.ShelfCharacteristic,
    path: DiffoExample.Access.PathCharacteristic,
    line: DiffoExample.Access.LineCharacteristic,
    dslam: DiffoExample.Access.DslamCharacteristic,
    aggregate_interface: DiffoExample.Access.AggregateCharacteristic,
    circuit: DiffoExample.Access.CircuitCharacteristic,
    constraints: DiffoExample.Access.ConstraintsCharacteristic
  }

  @doc """
  Checks expected values against typed characteristics or pool characteristics
  on the given instance.

  For pool names (#{inspect(@pool_names)}), queries AssignableCharacteristic directly.
  For typed characteristic names, queries the typed characteristic module directly.
  Expected values are keyword lists of field-name → Outstanding expectation pairs.
  """
  def check_values(expected_values, instance)
      when is_list(expected_values) and is_struct(instance) do
    Enum.each(expected_values, fn {name, expected} ->
      if name in @pool_names do
        check_pool(name, expected, instance)
      else
        check_characteristic(name, expected, instance)
      end
    end)
  end

  defp check_pool(pool_name, expected, instance) when is_list(expected) do
    {:ok, pool} =
      Diffo.Provider.AssignableCharacteristic
      |> Ash.Query.filter_input(instance_id: instance.id, name: pool_name)
      |> Ash.read_one()

    assert pool, "pool #{pool_name} not found on instance #{instance.id}"

    Enum.each(expected, fn {field, expected_value} ->
      actual = Map.get(pool, field)
      assert expected_value --- actual == nil
    end)
  end

  defp check_characteristic(role_name, expected, instance) when is_list(expected) do
    mod = Map.fetch!(@characteristic_modules, role_name)

    {:ok, char} =
      mod
      |> Ash.Query.filter_input(instance_id: instance.id)
      |> Ash.read_one()

    assert char, "characteristic #{role_name} not found on instance #{instance.id}"

    Enum.each(expected, fn {field, expected_value} ->
      actual = char.value |> Map.get(field)
      assert expected_value --- actual == nil
    end)
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Test.Characteristics do
  @moduledoc """
  Test support for Characteristics.

  Pool and typed-characteristic module lookups are derived from the
  configured Ash domains' Instance resources at runtime via
  `Ash.Domain.Info.resources/1` and `Diffo.Provider.Extension.Info` —
  no hand-maintained lists.
  """
  import Outstand
  import ExUnit.Assertions

  alias Diffo.Provider.Extension.Info, as: ProviderInfo

  @doc """
  Checks expected values against typed characteristics or pool characteristics
  on the given instance.

  For declared pool names, queries `AssignableCharacteristic` directly. For
  declared typed characteristic names, queries the typed characteristic module
  directly. Expected values are keyword lists of field-name → Outstanding
  expectation pairs.
  """
  def check_values(expected_values, instance)
      when is_list(expected_values) and is_struct(instance) do
    Enum.each(expected_values, fn {name, expected} ->
      if name in pool_names() do
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
    mod = Map.fetch!(characteristic_modules(), role_name)

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

  defp characteristic_modules do
    instance_resources()
    |> Enum.flat_map(fn mod ->
      Enum.map(mod.characteristics(), &{&1.name, &1.value_type})
    end)
    |> Map.new()
  end

  defp pool_names do
    instance_resources()
    |> Enum.flat_map(fn mod -> Enum.map(mod.pools(), & &1.name) end)
    |> Enum.uniq()
  end

  defp instance_resources do
    :diffo_example
    |> Application.get_env(:ash_domains, [])
    |> Enum.flat_map(&Ash.Domain.Info.resources/1)
    |> Enum.filter(&ProviderInfo.instance?/1)
  end
end

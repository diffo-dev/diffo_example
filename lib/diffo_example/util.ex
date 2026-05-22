# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Util do
  @moduledoc """
  Cross-domain projection helpers for the diffo_example app.

  Mirrors `Diffo.Util` in shape: each function is a *projection* — it
  collapses values in a JSON payload to a coarser semantic form so
  comparisons stay meaningful at the projected level. Apply the same
  projection to both sides of a comparison.
  """

  @absent_characteristic "absent_characteristic"

  @doc """
  Project the `*Characteristic` arrays in a JSON payload to a coarser
  form derived from `instance`'s declarations.

  General-purpose projection helper for comparing TMF payloads at the
  *names-only* level, ignoring the specific values carried by typed
  characteristic records and pool records. Reads the declared
  characteristic, pool and feature characteristic names from the
  instance's module and replaces each named characteristic array with a
  sorted list of `%{"name" => name, "value" => "absent_characteristic"}`
  entries. Applied to both sides of a comparison, names align and rich
  values collapse to the same placeholder.

  Useful for demonstrating projections — coarsening test assertions to
  the structural shape (which characteristics are declared and surface)
  without coupling them to the values those characteristics happen to
  carry on a given run.

  Modelled after `Diffo.Util.summarise_dates/1`.
  """
  def summarise_characteristics(payload, instance)
      when is_binary(payload) and is_struct(instance) do
    mod = instance.__struct__

    payload
    |> Jason.decode!()
    |> project_top(instance_field(instance), declared_characteristic_names(mod))
    |> project_features(feature_characteristic_names(mod))
    |> Jason.encode!()
  end

  defp instance_field(%{type: :service}), do: "serviceCharacteristic"
  defp instance_field(%{type: :resource}), do: "resourceCharacteristic"

  defp declared_characteristic_names(mod) do
    chars = Enum.map(mod.characteristics(), &Atom.to_string(&1.name))
    pools = Enum.map(mod.pools(), &Atom.to_string(&1.name))
    Enum.sort(chars ++ pools)
  end

  defp feature_characteristic_names(mod) do
    Map.new(mod.features(), fn feature ->
      names =
        feature.characteristics
        |> Enum.map(&Atom.to_string(&1.name))
        |> Enum.sort()

      {Atom.to_string(feature.name), names}
    end)
  end

  defp project_top(map, _field, []), do: map
  defp project_top(map, field, names), do: Map.put(map, field, placeholders(names))

  defp project_features(map, feature_chars) when map_size(feature_chars) == 0, do: map

  defp project_features(map, feature_chars) do
    case Map.get(map, "feature") do
      features when is_list(features) ->
        Map.put(map, "feature", Enum.map(features, &project_feature(&1, feature_chars)))

      _ ->
        map
    end
  end

  defp project_feature(%{"name" => name} = feature, feature_chars) do
    case Map.get(feature_chars, name) do
      nil -> feature
      [] -> feature
      names -> Map.put(feature, "featureCharacteristic", placeholders(names))
    end
  end

  defp project_feature(feature, _), do: feature

  defp placeholders(names) do
    Enum.map(names, &%{"name" => &1, "value" => @absent_characteristic})
  end
end

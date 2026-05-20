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

  @absent_characteristic "absent_diffo_169"

  @doc """
  Project the `*Characteristic` arrays in a JSON payload to a coarser
  form derived from `instance`'s declarations.

  While [diffo#169](https://github.com/diffo-dev/diffo/issues/169) is
  open, typed characteristic records and pool records do not collapse
  into the TMF `serviceCharacteristic` / `resourceCharacteristic` /
  `featureCharacteristic` arrays. Without this projection the actual
  JSON has no entries at all and the expected has rich entries.

  This projection reads the declared characteristic, pool and feature
  characteristic names from the instance's module and replaces each
  named characteristic array with a sorted list of
  `%{"name" => name, "value" => "absent_diffo_169"}` entries. Applied
  to both sides, names align; the rich value collapses to the same
  placeholder. When #169 lands and the collapse arrives, remove the
  `|> summarise_characteristics(instance)` wraps from each call site
  (or delete this function) — every previously masked test surfaces.

  Modelled after `Diffo.Util.summarise_dates/1`.
  """
  def summarise_characteristics(payload, instance) when is_binary(payload) and is_struct(instance) do
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

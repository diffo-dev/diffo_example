# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Path do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Path - Path Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Path"
    plural_name :Paths
  end

  specification do
    id "1d507914-8f76-48cb-aa0e-3a8f92951ab0"
    name "path"
    type :resourceSpecification
    description "A Path Resource Instance"
    category "Network Resource"
  end

  characteristics do
    characteristic :path, DiffoExample.Access.PathValue
  end

  actions do
    create :build do
      description "creates a new Path resource instance for build"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context ->
               changeset
               |> Specification.set_specified_by_argument()
               |> Feature.set_features_argument()
               |> Characteristic.set_characteristics_argument()
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Specification.relate_instance(result, changeset),
                    {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Feature.relate_instance(result, changeset),
                    {:ok, result} <- Characteristic.relate_instance(result, changeset),
                    {:ok, result} <- Place.relate_instance(result, changeset),
                    {:ok, result} <- Party.relate_instance(result, changeset),
                    {:ok, result} <- Access.get_path_by_id(result.id),
                    do: {:ok, result}
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the path"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Access.get_path_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the path with other instances"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Access.get_path_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Cable do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Cable - Cable Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Extension.Characteristic
  alias Diffo.Provider.Assigner
  alias Diffo.Provider.Assignment
  alias Diffo.Provider.Extension.Pool

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Cable"
    plural_name :Cables
  end

  provider do
    specification do
      id "ce0a567a-6abb-4862-9e33-851fd79fa595"
      name "cable"
      type :resourceSpecification
      description "A Cable Resource Instance"
      category "Network Resource"
    end

    characteristics do
      characteristic :cable, DiffoExample.Access.CableCharacteristic
    end

    pools do
      pool :pairs, :pair
    end

    relationships do
      source :all
      target :all
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      description "creates a new Cable resource instance for build"
      accept [:id, :name, :type, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the cable"
      argument :characteristic_value_updates, {:array, :term}

      change set_attribute(:resource_state, :operating)

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Ash.load(result, [:characteristics]),
                    {:ok, result} <- Characteristic.update_all(result, changeset, characteristics()),
                    {:ok, result} <- Pool.update_pools(result, changeset, pools()),
                    {:ok, result} <- Access.get_cable_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the cable with other instances"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Access.get_cable_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :assign_pair do
      description "relates the cable with an instance by assigning a pair"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Assigner.assign(result, changeset, :pairs),
                    {:ok, result} <- Access.get_cable_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

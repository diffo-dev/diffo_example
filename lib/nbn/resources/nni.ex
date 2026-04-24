# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Nni do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Nni - Network-to-Network Interface Resource Instance

  An NNI is the physical handover port between the NBN network and the
  Retail Service Provider (RSP). Multiple NNI resources are grouped within
  an NNI Group resource.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.ActionHelper

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "nni"
  end

  resource do
    description "An Ash Resource representing a Network-to-Network Interface (NNI)"
    plural_name :Nnis
  end

  specification do
    id "f6a7b8c9-0d1e-4f2a-9b3c-5d6e7f8a9b0c"
    name "nni"
    type :resourceSpecification
    description "An NNI Resource Instance that is part of an NNI Group"
    category "Network Resource"
  end

  characteristics do
    characteristic :nni, DiffoExample.Nbn.NniValue
  end

  actions do
    create :build do
      description "creates a new NNI resource instance"
      accept [:id, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change set_attribute(:name, &DiffoExample.Nbn.Nni.identifier/0)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_nni_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NNI"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_nni_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the NNI with other instances (e.g. its parent NNI Group)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_nni_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    def identifier() do
      DiffoExample.Nbn.Util.identifier("NNI")
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Avc do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Avc - Access Virtual Circuit Resource Instance

  An AVC is the virtual circuit dedicated to an NBN Ethernet circuit,
  carrying traffic between its related UNI and the CVC that aggregates it.
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
    type "avc"
  end

  resource do
    description "An Ash Resource representing an Access Virtual Circuit (AVC)"
    plural_name :Avcs
  end

  specification do
    id "b2c3d4e5-6f7a-4b8c-9d0e-1f2a3b4c5d6e"
    name "avc"
    type :resourceSpecification
    description "An AVC Resource Instance dedicated to an NBN Ethernet circuit"
    category "Network Resource"
  end

  characteristics do
    characteristic :avc, DiffoExample.Nbn.AvcValue
    characteristic :cvc, DiffoExample.Nbn.CvcValue
  end

  actions do
    create :build do
      description "creates a new AVC resource instance"
      accept [:id, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:name, &DiffoExample.Nbn.Avc.identifier/0)

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_avc_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the AVC"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_avc_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the AVC with other instances"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_avc_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :mine do
      description "updates the AVC with data mined from related instances"
      argument :characteristic_value_updates, {:array, :term}

      change before_action(fn changeset, context ->
               DiffoExample.Nbn.Avc.mine_related(changeset, context)
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_avc_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("AVC")
  end

  # mines related resource to characteristics
  def mine_related(changeset, _context) when is_struct(changeset, Ash.Changeset) do
    avc = Ash.load!(changeset.data, [reverse_relationships: [:characteristics]])

    cvlan = {:cvlan, Diffo.Unwrap.unwrap(hd(hd(avc.reverse_relationships).characteristics).value)}

    Ash.Changeset.force_set_argument(changeset, :characteristic_value_updates, avc: [cvlan])
  end
end

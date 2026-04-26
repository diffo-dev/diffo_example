# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Uni do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Uni - User Network Interface Resource Instance

  A UNI is the physical/logical interface at the customer premises. It is
  related to an NTD resource and to its parent NBN Ethernet access.
  It is related to an AVC resource, which is in turn aggregated by a CVC.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.ActionHelper

  alias DiffoExample.Nbn
  alias DiffoExample.Nbn.Util

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn,
    extensions: [AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  json_api do
    type "uni"
  end

  resource do
    description "An Ash Resource representing a User Network Interface (UNI)"
    plural_name :Unis
  end

  specification do
    id "a1b2c3d4-5e6f-4a7b-8c9d-0e1f2a3b4c5d"
    name "uni"
    type :resourceSpecification
    description "A UNI Resource Instance related to an NTD and an NBN Ethernet access"
    category "Network Resource"
  end

  characteristics do
    characteristic :uni, DiffoExample.Nbn.UniValue
  end

  actions do
    create :build do
      description "creates a new UNI resource instance"
      accept [:id, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change set_attribute(:name, &DiffoExample.Nbn.Uni.identifier/0)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_uni_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the UNI"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_uni_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the UNI with other instances (e.g. NTD, NBN Ethernet access)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_uni_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :mine do
      description "updates the UNI with data mined from related instances"
      argument :characteristic_value_updates, {:array, :term}

      change before_action(fn changeset, context ->
               DiffoExample.Nbn.Uni.mine_related(changeset, context)
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_uni_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("UNI")
  end

  # mines related resource to characteristics
  def mine_related(changeset, _context) when is_struct(changeset, Ash.Changeset) do
    uni = Ash.load!(changeset.data, [reverse_relationships: [:characteristics]])

    ntd_relationship = hd(uni.reverse_relationships)

    port = {:port, Diffo.Unwrap.unwrap(hd(ntd_relationship.characteristics).value)}
    {:ok, ntd} = Diffo.Provider.get_instance_by_id(ntd_relationship.source_id)
    technology = {:technology, Util.extract(ntd.characteristics, :ntd, :technology)}

    Ash.Changeset.force_set_argument(changeset, :characteristic_value_updates,
      uni: [port, technology]
    )
  end

  policies do
    bypass DiffoExample.Nbn.Checks.NoActor do
      authorize_if always()
    end

    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end
end

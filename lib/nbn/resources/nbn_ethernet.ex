# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NbnEthernet do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NbnEthernet - NBN Ethernet access Resource Instance

  An NBN Ethernet access comprising a dedicated UNI and AVC resource.
  The access is related to its UNI, which in turn is aggregated by a CVC
  that terminates at an NNI Group.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.ActionHelper

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn

  resource do
    description "An Ash Resource representing an NBN Ethernet access"
    plural_name :NbnEthernets
  end

  specification do
    id "f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c"
    name "nbnEthernet"
    type :resourceSpecification
    description "An NBN Ethernet access comprising a dedicated UNI and AVC"
    category "Network Resource"
  end

  characteristics do
    characteristic :pri, DiffoExample.Nbn.PriValue
    # values do
    #  value :uniid, DiffoExample.Nbn.Uni, :owns, :name
    #  value :avcid, DiffoExample.Nbn.Avc, :owns, :name
    # end
  end

  actions do
    create :build do
      description "creates a new NBN Ethernet access resource instance"
      accept [:id, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:name, &DiffoExample.Nbn.NbnEthernet.identifier/0)

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_nbn_ethernet_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NBN Ethernet access"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_nbn_ethernet_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the NBN Ethernet access with other instances (e.g. UNI)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_nbn_ethernet_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :mine do
      description "updates the NBN Ethernet access with data mined from related instances"
      argument :characteristic_value_updates, {:array, :term}

      change before_action(fn changeset, context ->
               DiffoExample.Nbn.NbnEthernet.mine_related(changeset, context)
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_nbn_ethernet_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("PRI")
  end

  # mines related resource to characteristics
  def mine_related(changeset, _context) when is_struct(changeset, Ash.Changeset) do
    forward_relationships = Ash.Changeset.get_attribute(changeset, :forward_relationships)

    pri_updates =
      Enum.into(forward_relationships, [], fn forward_relationship ->
        {:ok, related} = Diffo.Provider.get_instance_by_id(forward_relationship.target_id)
        {alias_to_id(forward_relationship.alias), related.name}
      end)

    Ash.Changeset.force_set_argument(changeset, :characteristic_value_updates, pri: pri_updates)
  end

  defp alias_to_id(alias) when is_atom(alias) do
    (Atom.to_string(alias) <> "id")
    |> String.to_atom()
  end
end

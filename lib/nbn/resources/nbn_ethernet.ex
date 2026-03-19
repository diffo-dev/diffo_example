# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NbnEthernet do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NbnEthernet - NBN Ethernet Circuit Resource Instance

  An NBN Ethernet circuit comprising a dedicated UNI and AVC resource.
  The circuit is related to its UNI, which in turn is aggregated by a CVC
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
    description "An Ash Resource representing an NBN Ethernet Circuit"
    plural_name :NbnEthernets
  end

  specification do
    id "f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c"
    name "nbnEthernet"
    type :resourceSpecification
    description "An NBN Ethernet Circuit comprising a dedicated UNI and AVC"
    category "Network Resource"
  end

  characteristics do
    characteristic :nbn_ethernet, DiffoExample.Nbn.NbnEthernetValue
  end

  actions do
    create :build do
      description "creates a new NBN Ethernet circuit resource instance"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_nbn_ethernet_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NBN Ethernet circuit"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_nbn_ethernet_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the NBN Ethernet circuit with other instances (e.g. UNI)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_nbn_ethernet_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

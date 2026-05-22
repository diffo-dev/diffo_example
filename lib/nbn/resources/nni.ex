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

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn,
    extensions: [AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  resource do
    description "An Ash Resource representing a Network-to-Network Interface (NNI)"
    plural_name :Nnis
  end

  json_api do
    type "nni"
  end

  provider do
    specification do
      id "f6a7b8c9-0d1e-4f2a-9b3c-5d6e7f8a9b0c"
      name "nni"
      type :resourceSpecification
      description "An NNI Resource Instance that is part of an NNI Group"
      category "Network Resource"
    end

    characteristics do
      characteristic :nni, DiffoExample.Nbn.NniCharacteristic
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
      description "creates a new NNI resource instance"
      accept [:id, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change set_attribute(:name, &DiffoExample.Nbn.Nni.identifier/0)
      change DiffoExample.Nbn.Changes.SetRspId
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NNI"
      argument :characteristic_value_updates, {:array, :term}

      change set_attribute(:resource_state, :operating)
      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the NNI with other instances (e.g. its parent NNI Group)"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end
  end

  attributes do
    attribute :rsp_id, :string do
      description "the owning RSP's id — nil for Perentie-managed infrastructure"
      allow_nil? true
      public? true
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("NNI")
  end

  use DiffoExample.Nbn.RspOwnership
end

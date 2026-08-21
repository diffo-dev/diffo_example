# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Npt.Synchronisation do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Synchronisation - Synchronisation Service Instance

  The NPT domain's first service: delivery of traceable time, phase and
  frequency to a consuming site or network element.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Service

  alias DiffoExample.Npt

  use Ash.Resource,
    fragments: [BaseInstance, Service],
    domain: Npt

  resource do
    description "An Ash Resource representing a Synchronisation Service"
    plural_name :Synchronisations
  end

  provider do
    specification do
      id "9aaac60e-53ea-43a7-a5e2-f342f281aad5"
      name "synchronisation"
      type :serviceSpecification
      description "A Synchronisation Service delivering traceable time, phase and frequency"
      category "Timing Service"
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
      description "creates a new Synchronisation service instance"
      accept [:id, :name, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :service)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the Synchronisation service"
      argument :characteristic_value_updates, {:array, :term}

      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the Synchronisation service with other instances"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end
  end
end

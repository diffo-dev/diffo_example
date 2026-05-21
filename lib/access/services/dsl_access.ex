# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.DslAccess do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  DslAccess - DSL Access Service Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Place

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a DSL Access Service"
    plural_name :DslAccesses
  end

  provider do
    specification do
      id "da9b207a-26c3-451d-8abd-0640c6349979"
      name "dslAccess"
      description "A DSL Access Network Service connecting a subscriber premises to an NNI"
      category "Network Service"
    end

    features do
      feature :dynamic_line_management do
        is_enabled? true
        characteristic :constraints, DiffoExample.Access.ConstraintsCharacteristic
      end
    end

    characteristics do
      characteristic :dslam, DiffoExample.Access.DslamCharacteristic
      characteristic :aggregate_interface, DiffoExample.Access.AggregateCharacteristic
      characteristic :circuit, DiffoExample.Access.CircuitCharacteristic
      characteristic :line, DiffoExample.Access.LineCharacteristic
    end

    behaviour do
      actions do
        create :qualify
      end
    end
  end

  state_machine do
    transitions do
      transition action: :qualify_result, from: :initial, to: :inactive
      transition action: :design_result, from: [:initial, :inactive], to: :reserved
    end
  end

  actions do
    create :qualify do
      description "creates a new DSL Access service instance for qualification"
      accept [:id, :name, :type, :which]
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change load [:href]
      upsert? false
    end

    update :qualify_result do
      description "updates the DSL Access service with qualification result"
      accept [:service_operating_status]
      argument :places, {:array, :struct}
      require_atomic? false

      change transition_state(:inactive)

      validate argument_in(:service_operating_status, [
                 nil,
                 :initial,
                 :pending,
                 :unknown,
                 :feasible,
                 :not_feasible
               ])

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Place.relate_instance(result, changeset),
                    {:ok, result} <- Access.get_dsl_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :design_result do
      description "updates the DSL Access service with the design"
      argument :characteristic_value_updates, {:array, :term}

      change transition_state(:reserved)
      change DiffoExample.Changes.Define
    end
  end
end

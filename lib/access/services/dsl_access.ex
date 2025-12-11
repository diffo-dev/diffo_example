# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.DslAccess do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  DslAccess - DSL Access Service Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.ActionHelper

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a DSL Access Service"
    plural_name :DslAccesses
  end

  specification do
    id "da9b207a-26c3-451d-8abd-0640c6349979"
    name "dslAccess"
    description "A DSL Access Network Service connecting a subscriber premises to an NNI"
    category "Network Service"
  end

  features do
    feature :dynamic_line_management do
      is_enabled? true
      characteristic :constraints, DiffoExample.Access.Constraints
    end
  end

  characteristics do
    characteristic :dslam, DiffoExample.Access.Dslam
    characteristic :aggregate_interface, DiffoExample.Access.AggregateInterface
    characteristic :circuit, DiffoExample.Access.Circuit
    characteristic :line, DiffoExample.Access.Line
  end

  state_machine do
    transitions do
      transition action: :qualify_result, from: :initial, to: :feasibilityChecked
      transition action: :design_result, from: [:initial, :feasibilityChecked], to: :reserved
    end
  end

  actions do
    create :qualify do
      description "creates a new DSL Access service instance for qualification"
      accept [:id, :name, :type, :which]
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}
      argument :specified_by, :uuid, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :features, {:array, :uuid}, public?: false

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Access, :get_dsl_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :qualify_result do
      description "updates the DSL Access service with qualification result"
      accept [:service_operating_status]
      argument :places, {:array, :struct}
      require_atomic? false

      change transition_state(:feasibilityChecked)

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

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Access.get_dsl_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

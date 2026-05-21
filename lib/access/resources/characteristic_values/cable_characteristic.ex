# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.CableCharacteristic do
  @moduledoc "Typed characteristic for a Cable's physical properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  alias DiffoExample.Access.CharacteristicChanges

  resource do
    description "Typed characteristic carrying cable physical property fields"
    plural_name :cable_characteristics
  end

  actions do
    create :create do
      accept [:name, :pairs, :length_amount, :length_unit, :loss_amount, :loss_unit, :technology]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:pairs, :technology, :length_amount, :length_unit, :loss_amount, :loss_unit]
      argument :length, :term, allow_nil?: true
      argument :loss, :term, allow_nil?: true

      change fn changeset, _ ->
        changeset
        |> CharacteristicChanges.set_unit(:length, :length_amount, :length_unit)
        |> CharacteristicChanges.set_unit(:loss, :loss_amount, :loss_unit)
      end
    end
  end

  attributes do
    attribute :pairs, :integer, public?: true
    attribute :length_amount, :integer, public?: true
    attribute :length_unit, :atom, public?: true
    attribute :loss_amount, :float, public?: true
    attribute :loss_unit, :atom, public?: true
    attribute :technology, :atom, public?: true
  end

  calculations do
    calculate :value,
              Diffo.Type.CharacteristicValue,
              DiffoExample.Access.CableCharacteristic.ValueCalculation do
      public? true
    end
  end

  preparations do
    prepare build(load: [:value])
  end

  jason do
    pick [:name, :value]
    compact true
  end
end

defmodule DiffoExample.Access.CableCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Access.IntegerUnit
  alias DiffoExample.Access.FloatUnit

  jason do
    pick [:pairs, :length, :loss, :technology]
    compact true
  end

  outstanding do
    expect [:pairs, :loss]
  end

  typed_struct do
    field :pairs, :integer
    field :length, IntegerUnit
    field :loss, FloatUnit
    field :technology, :atom
  end
end

defmodule DiffoExample.Access.CableCharacteristic.ValueCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  alias DiffoExample.Access.IntegerUnit
  alias DiffoExample.Access.FloatUnit
  alias DiffoExample.Access.CableCharacteristic

  @impl true
  def load(_, _, _), do: []

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn r ->
      %CableCharacteristic.Value{
        pairs: r.pairs,
        length:
          if r.length_amount do
            %IntegerUnit{amount: r.length_amount, unit: r.length_unit}
          end,
        loss:
          if r.loss_amount do
            %FloatUnit{amount: r.loss_amount, unit: r.loss_unit}
          end,
        technology: r.technology
      }
    end)
  end
end

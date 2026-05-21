# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.PathCharacteristic do
  @moduledoc "Typed characteristic for a Path's physical properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  alias DiffoExample.Access.CharacteristicChanges

  resource do
    description "Typed characteristic carrying path physical property fields"
    plural_name :path_characteristics
  end

  actions do
    create :create do
      accept [
        :name,
        :device_name,
        :sections,
        :length_amount,
        :length_unit,
        :loss_amount,
        :loss_unit,
        :technology
      ]

      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [
        :device_name,
        :sections,
        :technology,
        :length_amount,
        :length_unit,
        :loss_amount,
        :loss_unit
      ]

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
    attribute :device_name, :string, public?: true
    attribute :sections, :integer, public?: true
    attribute :length_amount, :integer, public?: true
    attribute :length_unit, :atom, public?: true
    attribute :loss_amount, :float, public?: true
    attribute :loss_unit, :atom, public?: true
    attribute :technology, :atom, public?: true
  end

  calculations do
    calculate :value,
              Diffo.Type.CharacteristicValue,
              DiffoExample.Access.PathCharacteristic.ValueCalculation do
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

defmodule DiffoExample.Access.PathCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Access.IntegerUnit
  alias DiffoExample.Access.FloatUnit

  jason do
    pick [:device_name, :sections, :length, :loss, :technology]
    compact true
    rename device_name: "name"
  end

  outstanding do
    expect [:loss]
  end

  typed_struct do
    field :device_name, :string
    field :sections, :integer
    field :length, IntegerUnit
    field :loss, FloatUnit
    field :technology, :atom
  end
end

defmodule DiffoExample.Access.PathCharacteristic.ValueCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  alias DiffoExample.Access.IntegerUnit
  alias DiffoExample.Access.FloatUnit
  alias DiffoExample.Access.PathCharacteristic

  @impl true
  def load(_, _, _), do: []

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn r ->
      %PathCharacteristic.Value{
        device_name: r.device_name,
        sections: r.sections,
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

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Access - example Access domain
  """
  use Ash.Domain,
    otp_app: :diffo,
    fragments: [Diffo.Provider.DomainFragment],
    extensions: [AshAi]

  alias DiffoExample.Access.DslAccess
  alias DiffoExample.Access.Shelf
  alias DiffoExample.Access.Card
  alias DiffoExample.Access.Cable
  alias DiffoExample.Access.Path
  alias DiffoExample.Access.CableCharacteristic
  alias DiffoExample.Access.CardCharacteristic
  alias DiffoExample.Access.ShelfCharacteristic
  alias DiffoExample.Access.PathCharacteristic
  alias DiffoExample.Access.LineCharacteristic
  alias DiffoExample.Access.DslamCharacteristic
  alias DiffoExample.Access.AggregateCharacteristic
  alias DiffoExample.Access.CircuitCharacteristic
  alias DiffoExample.Access.ConstraintsCharacteristic

  domain do
    description "An example showing how TMF Services and Resources for a fictional Access domain can be extended from the Provider domain"
  end

  tools do
    tool :get_dsl_by_id, DslAccess, :read
    tool :qualify_dsl, DslAccess, :qualify
    tool :qualify_dsl_result, DslAccess, :qualify_result
    tool :design_dsl_result, DslAccess, :design_result

    tool :get_shelf_by_id, Shelf, :read
    tool :build_shelf, Shelf, :build
    tool :define_shelf, Shelf, :define
    tool :relate_shelf, Shelf, :relate
    tool :assign_slot, Shelf, :assign_slot

    tool :get_card_by_id, Card, :read
    tool :build_card, Card, :build
    tool :define_card, Card, :define
    tool :relate_card, Card, :relate
    tool :assign_port_on_card, Card, :assign_port

    tool :get_cable_by_id, Cable, :read
    tool :build_cable, Cable, :build
    tool :define_cable, Cable, :define
    tool :relate_cable, Cable, :relate
    tool :assign_pair, Cable, :assign_pair

    tool :get_path_by_id, Path, :read
    tool :build_path, Path, :build
    tool :define_path, Path, :define
    tool :relate_path, Path, :relate
  end

  resources do
    resource DslAccess do
      define :get_dsl_by_id, action: :read, get_by: :id
      define :qualify_dsl, action: :qualify
      define :qualify_dsl_result, action: :qualify_result
      define :design_dsl_result, action: :design_result
    end

    resource Shelf do
      define :get_shelf_by_id, action: :read, get_by: :id
      define :build_shelf, action: :build
      define :define_shelf, action: :define
      define :relate_shelf, action: :relate
      define :assign_slot, action: :assign_slot
    end

    resource Card do
      define :get_card_by_id, action: :read, get_by: :id
      define :build_card, action: :build
      define :define_card, action: :define
      define :relate_card, action: :relate
      define :assign_port, action: :assign_port
    end

    resource Cable do
      define :get_cable_by_id, action: :read, get_by: :id
      define :build_cable, action: :build
      define :define_cable, action: :define
      define :relate_cable, action: :relate
      define :assign_pair, action: :assign_pair
    end

    resource Path do
      define :get_path_by_id, action: :read, get_by: :id
      define :build_path, action: :build
      define :define_path, action: :define
      define :relate_path, action: :relate
    end

    resource CableCharacteristic
    resource CardCharacteristic
    resource ShelfCharacteristic
    resource PathCharacteristic
    resource LineCharacteristic
    resource DslamCharacteristic
    resource AggregateCharacteristic
    resource CircuitCharacteristic
    resource ConstraintsCharacteristic
  end
end

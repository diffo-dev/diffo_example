# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Test.Parties do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Parties - Test support for Parties
  """

  import ExUnit.Assertions

  def check_parties(expected_parties, instance)
      when is_list(expected_parties) and is_struct(instance) do
    Enum.zip_reduce(expected_parties, instance.parties, [], fn _expected_party,
                                                               actual_party_ref,
                                                               _acc ->
      assert is_struct(actual_party_ref, Diffo.Provider.PartyRef)
      refute is_nil(actual_party_ref.party_id)
      assert is_struct(actual_party_ref.party, Diffo.Provider.Party)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :PartyRef,
               %{uuid: actual_party_ref.id},
               :RELATES,
               :outgoing
             )

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :PartyRef,
               %{uuid: actual_party_ref.id},
               :Party,
               %{key: actual_party_ref.party_id},
               :RELATES,
               :outgoing
             )
    end)
  end
end

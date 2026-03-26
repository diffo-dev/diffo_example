# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Nbn - example NBN domain

  Models NBN network resources including the Ethernet circuit (NbnEthernet)
  and its constituent resources: UNI (dedicated), AVC (dedicated), NTD,
  CVC (aggregates AVCs, terminates at NNI Group), NNI Group, and NNI.
  """
  use Ash.Domain,
    otp_app: :diffo

  alias DiffoExample.Nbn.NbnEthernet
  alias DiffoExample.Nbn.Uni
  alias DiffoExample.Nbn.Avc
  alias DiffoExample.Nbn.Ntd
  alias DiffoExample.Nbn.Cvc
  alias DiffoExample.Nbn.NniGroup
  alias DiffoExample.Nbn.Nni

  domain do
    description "An example showing how TMF Resources for a fictional NBN domain can be extended from the Provider domain"
  end

  resources do
    resource NbnEthernet do
      define :get_nbn_ethernet_by_id, action: :read, get_by: :id
      define :build_nbn_ethernet, action: :build
      define :define_nbn_ethernet, action: :define
      define :relate_nbn_ethernet, action: :relate
      define :mine_nbn_ethernet, action: :mine
    end

    resource Uni do
      define :get_uni_by_id, action: :read, get_by: :id
      define :build_uni, action: :build
      define :define_uni, action: :define
      define :relate_uni, action: :relate
      define :mine_uni, action: :mine
    end

    resource Avc do
      define :get_avc_by_id, action: :read, get_by: :id
      define :build_avc, action: :build
      define :define_avc, action: :define
      define :relate_avc, action: :relate
      define :mine_avc, action: :mine
    end

    resource Ntd do
      define :get_ntd_by_id, action: :read, get_by: :id
      define :build_ntd, action: :build
      define :define_ntd, action: :define
      define :assign_port, action: :assign_port
      define :relate_ntd, action: :relate
    end

    resource Cvc do
      define :get_cvc_by_id, action: :read, get_by: :id
      define :build_cvc, action: :build
      define :define_cvc, action: :define
      define :assign_cvlan, action: :assign_cvlan
      define :relate_cvc, action: :relate
      define :mine_cvc, action: :mine
    end

    resource NniGroup do
      define :get_nni_group_by_id, action: :read, get_by: :id
      define :build_nni_group, action: :build
      define :define_nni_group, action: :define
      define :assign_svlan, action: :assign_svlan
      define :relate_nni_group, action: :relate
    end

    resource Nni do
      define :get_nni_by_id, action: :read, get_by: :id
      define :build_nni, action: :build
      define :define_nni, action: :define
      define :relate_nni, action: :relate
    end
  end
end

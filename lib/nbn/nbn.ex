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
    otp_app: :diffo,
    fragments: [Diffo.Provider.DomainFragment],
    extensions: [AshAi, AshJsonApi.Domain]

  alias DiffoExample.Nbn.NbnEthernet
  alias DiffoExample.Nbn.Uni
  alias DiffoExample.Nbn.Avc
  alias DiffoExample.Nbn.Ntd
  alias DiffoExample.Nbn.Cvc
  alias DiffoExample.Nbn.NniGroup
  alias DiffoExample.Nbn.Nni
  alias DiffoExample.Nbn.Rsp
  alias DiffoExample.Nbn.AvcCharacteristic
  alias DiffoExample.Nbn.CvcCharacteristic
  alias DiffoExample.Nbn.NniGroupCharacteristic
  alias DiffoExample.Nbn.NniCharacteristic
  alias DiffoExample.Nbn.NtdCharacteristic
  alias DiffoExample.Nbn.UniCharacteristic
  alias DiffoExample.Nbn.PriCharacteristic

  domain do
    description "An example showing how TMF Resources for a fictional NBN domain can be extended from the Provider domain"
  end

  tools do
    tool :get_nbn_ethernet_by_id, NbnEthernet, :read
    tool :build_nbn_ethernet, NbnEthernet, :build
    tool :define_nbn_ethernet, NbnEthernet, :define
    tool :relate_nbn_ethernet, NbnEthernet, :relate

    tool :get_uni_by_id, Uni, :read
    tool :build_uni, Uni, :build
    tool :define_uni, Uni, :define
    tool :relate_uni, Uni, :relate

    tool :get_avc_by_id, Avc, :read
    tool :build_avc, Avc, :build
    tool :define_avc, Avc, :define
    tool :relate_avc, Avc, :relate

    tool :get_ntd_by_id, Ntd, :read
    tool :build_ntd, Ntd, :build
    tool :define_ntd, Ntd, :define
    tool :assign_port_on_ntd, Ntd, :assign_port
    tool :relate_ntd, Ntd, :relate

    tool :get_cvc_by_id, Cvc, :read
    tool :build_cvc, Cvc, :build
    tool :define_cvc, Cvc, :define
    tool :assign_cvlan, Cvc, :assign_cvlan
    tool :relate_cvc, Cvc, :relate

    tool :get_nni_group_by_id, NniGroup, :read
    tool :build_nni_group, NniGroup, :build
    tool :define_nni_group, NniGroup, :define
    tool :assign_svlan, NniGroup, :assign_svlan
    tool :relate_nni_group, NniGroup, :relate

    tool :get_nni_by_id, Nni, :read
    tool :build_nni, Nni, :build
    tool :define_nni, Nni, :define
    tool :relate_nni, Nni, :relate

    tool :list_rsps, Rsp, :inventory
    tool :get_rsp_by_epid, Rsp, :read
    tool :create_rsp, Rsp, :build
    tool :activate_rsp, Rsp, :activate
    tool :suspend_rsp, Rsp, :suspend
    tool :deactivate_rsp, Rsp, :deactivate
  end

  json_api do
    routes do
      base_route "/nbnEthernet", NbnEthernet do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        delete :destroy
      end

      base_route "/uni", Uni do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        delete :destroy
      end

      base_route "/avc", Avc do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        delete :destroy
      end

      base_route "/ntd", Ntd do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        delete :destroy
      end

      base_route "/cvc", Cvc do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        delete :destroy
      end

      base_route "/nniGroup", NniGroup do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        delete :destroy
      end

      base_route "/nni", Nni do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        delete :destroy
      end

      base_route "/rsp", Rsp do
        get :read
      end
    end
  end

  resources do
    resource NbnEthernet do
      define :get_nbn_ethernet_by_id, action: :read, get_by: :id
      define :build_nbn_ethernet, action: :build
      define :define_nbn_ethernet, action: :define
      define :relate_nbn_ethernet, action: :relate
    end

    resource Uni do
      define :get_uni_by_id, action: :read, get_by: :id
      define :build_uni, action: :build
      define :define_uni, action: :define
      define :relate_uni, action: :relate
    end

    resource Avc do
      define :get_avc_by_id, action: :read, get_by: :id
      define :build_avc, action: :build
      define :define_avc, action: :define
      define :relate_avc, action: :relate
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

    resource Rsp do
      define :list_rsps, action: :inventory
      define :get_rsp_by_epid, action: :read, get_by: :id
      define :get_rsp_by_short_name, action: :read, get_by: :short_name
      define :create_rsp, action: :build
      define :activate_rsp, action: :activate
      define :suspend_rsp, action: :suspend
      define :deactivate_rsp, action: :deactivate
    end

    resource AvcCharacteristic
    resource CvcCharacteristic
    resource NniGroupCharacteristic
    resource NniCharacteristic
    resource NtdCharacteristic
    resource UniCharacteristic
    resource PriCharacteristic
  end
end

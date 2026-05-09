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
    extensions: [AshJsonApi.Domain]

  alias DiffoExample.Nbn.NbnEthernet
  alias DiffoExample.Nbn.Uni
  alias DiffoExample.Nbn.Avc
  alias DiffoExample.Nbn.Ntd
  alias DiffoExample.Nbn.Cvc
  alias DiffoExample.Nbn.NniGroup
  alias DiffoExample.Nbn.Nni
  alias DiffoExample.Nbn.Rsp

  domain do
    description "An example showing how TMF Resources for a fictional NBN domain can be extended from the Provider domain"
  end

  json_api do
    routes do
      base_route "/nbnEthernet", NbnEthernet do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        patch :mine, route: "/:id/mine"
        delete :destroy
      end

      base_route "/uni", Uni do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        patch :mine, route: "/:id/mine"
        delete :destroy
      end

      base_route "/avc", Avc do
        index :read
        get :read
        post :build
        patch :define
        patch :relate, route: "/:id/relate"
        patch :mine, route: "/:id/mine"
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
        patch :mine, route: "/:id/mine"
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

    resource Rsp do
      define :list_rsps, action: :inventory
      define :get_rsp_by_epid, action: :read, get_by: :id
      define :get_rsp_by_short_name, action: :read, get_by: :short_name
      define :create_rsp, action: :build
      define :activate_rsp, action: :activate
      define :suspend_rsp, action: :suspend
      define :deactivate_rsp, action: :deactivate
    end
  end
end

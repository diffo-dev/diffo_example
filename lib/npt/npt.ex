# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Npt do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Npt - example Navigation, Positioning and Timing domain

  Models the services and resources that distribute trusted time, frequency
  and position. Its first service is Synchronisation.
  """
  use Ash.Domain,
    otp_app: :diffo,
    fragments: [Diffo.Provider.DomainFragment],
    extensions: [AshAi]

  alias DiffoExample.Npt.Synchronisation

  domain do
    description "An example showing how TMF Services and Resources for a fictional Navigation, Positioning and Timing domain can be extended from the Provider domain"
  end

  tools do
    tool :get_synchronisation_by_id, Synchronisation, :read
    tool :build_synchronisation, Synchronisation, :build
    tool :define_synchronisation, Synchronisation, :define
    tool :relate_synchronisation, Synchronisation, :relate
  end

  resources do
    resource Synchronisation do
      define :get_synchronisation_by_id, action: :read, get_by: :id
      define :build_synchronisation, action: :build
      define :define_synchronisation, action: :define
      define :relate_synchronisation, action: :relate
    end
  end
end

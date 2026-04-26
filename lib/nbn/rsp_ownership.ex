# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.RspOwnership do
  @moduledoc """
  Shared RSP ownership policies for NBN resources.

  Injects the standard three-tier policy into any RSP-owned resource:
  - nil actor → bypass (internal Perentie calls)
  - admin role → bypass
  - create with RSP actor → allowed (rsp_id stamped by SetRspId)
  - read/update/destroy → RSP can only access its own records
  """

  defmacro __using__(_opts) do
    quote do
      policies do
        bypass DiffoExample.Nbn.Checks.NoActor do
          authorize_if always()
        end

        bypass actor_attribute_equals(:role, :admin) do
          authorize_if always()
        end

        policy action_type(:create) do
          authorize_if always()
        end

        policy action_type([:read, :update, :destroy]) do
          authorize_if DiffoExample.Nbn.Checks.OwnedByActor
        end
      end
    end
  end
end

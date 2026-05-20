# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.ApiRouter do
  @moduledoc false
  use AshJsonApi.Router,
    domains: [DiffoExample.Nbn],
    open_api: "/open_api"
end

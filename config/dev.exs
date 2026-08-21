# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

import Config

config :bolty, Bolt,
  uri: "bolt://localhost:7687",
  auth: [username: "neo4j", password: "password"],
  user_agent: "DiffoExampleDev/1",
  pool_size: 15,
  name: Bolt

level =
  if System.get_env("DEBUG") do
    :debug
  else
    :info
  end

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

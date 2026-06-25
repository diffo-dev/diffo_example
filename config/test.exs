# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

import Config

config :logger, level: :warning
config :ash, disable_async?: true
config :ash, :missed_notifications, :ignore

config :bolty, Bolt,
  uri: "bolt://localhost:7687",
  auth: [username: "neo4j", password: "password"],
  user_agent: "DiffoExampleTest/1",
  pool_size: 15,
  max_overflow: 3,
  prefix: :default,
  name: Bolt,
  # The AshNeo4j.Sandbox holds one connection (an open transaction) for the whole
  # test. DBConnection's default 15s checkout timeout disconnects a heavy test
  # mid-run on slower CI (the 5STI seed), cascading "connection is closed" errors.
  # Raise the pool default so a slow checkout completes. See #72.
  timeout: 60_000,
  log: true,
  log_hex: true

level =
  if System.get_env("DEBUG") do
    :debug
  else
    :info
  end

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

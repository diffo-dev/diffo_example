# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

Mix.Task.run("app.start")
level = Application.get_env(:logger, :console) |> Keyword.get(:level)
Logger.put_application_level(:diffo, level)
Logger.put_application_level(:ash_neo4j, :error)
AshNeo4j.Neo4jHelper.delete_all()

# The NBN standing infrastructure — RSPs, geo places, the 5STI service edge —
# is a fixture, not per-test data: it never changes and every test that needs it
# needs the same thing. Seed it once here, committed, so each test's sandbox
# rolls back only what that test itself writes. Seeding it per test cost ~3.9s
# each and was what pushed InterceptTest past the connection timeout (#77).
DiffoExample.Nbn.Initializer.init()

ExUnit.start(exclude: [:show_neo4j])

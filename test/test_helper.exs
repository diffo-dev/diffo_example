# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

Mix.Task.run("app.start")
level = Application.get_env(:logger, :console) |> Keyword.get(:level)
Logger.put_application_level(:diffo, level)
Logger.put_application_level(:ash_neo4j, :error)
AshNeo4j.Neo4jHelper.delete_all()
ExUnit.start(exclude: [:show_json])

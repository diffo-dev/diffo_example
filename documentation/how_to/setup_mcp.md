<!--
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Setting up the diffo_example MCP server

This how-to walks through running the diffo_example MCP server locally and
wiring AI clients (Claude Code, Claude Desktop, Cursor, custom) to it. The MCP
surface exposes every action declared in the Access and Nbn domains' `tools do`
blocks as a callable tool — 60 tools across the two domains as of writing.

See [issue #44](https://github.com/diffo-dev/diffo_example/issues/44) for the
design context, and Zach's
[Ash AI blog post](https://alembic.com.au/blog/ash-ai-comprehensive-llm-toolbox-for-ash-framework)
for the framing.

## Prerequisites

- Elixir / Erlang installed (per `mix.exs` — currently `~> 1.18`).
- Neo4j running locally with the credentials configured in `config/dev.exs`.
- Dependencies fetched: `mix deps.get`.
- Initial RSP data seeded on first start (handled automatically by
  `DiffoExample.Nbn.Initializer` when the app starts in dev).

## Starting the server

In a terminal in the project root:

```bash
MIX_ENV=dev mix run --no-halt
```

This boots the supervision tree, including `Plug.Cowboy` on port 4000. The MCP
server is forwarded from `DiffoExample.Nbn.Router` at the path `/mcp`. The same
Cowboy listener also serves the JSON:API routes and the `/catalog` endpoint.

You'll see Neo4j connection logs, then the listener-bound message. Leave it
running.

## Verifying MCP is up

In a second terminal, send the three canonical MCP requests with `curl`.

### `initialize`

```bash
curl -sS -X POST -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"initialize",
    "id":1,
    "params":{
      "protocolVersion":"2024-11-05",
      "capabilities":{},
      "clientInfo":{"name":"curl","version":"0"}
    }
  }' \
  http://localhost:4000/mcp
```

Expected response shape:

```json
{
  "id": 1,
  "jsonrpc": "2.0",
  "result": {
    "capabilities": {"tools": {"listChanged": false}},
    "protocolVersion": "2024-11-05",
    "serverInfo": {"name": "MCP Server", "version": "0.2.1"}
  }
}
```

### `tools/list`

```bash
curl -sS -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}' \
  http://localhost:4000/mcp
```

Returns the full set of tools. Each tool entry includes `name`, `description`,
and `inputSchema` (JSON Schema generated from the underlying Ash action's
arguments). To count and peek at the first few names:

```bash
curl -sS -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}' \
  http://localhost:4000/mcp |
  python3 -c '
import json, sys
d = json.load(sys.stdin)
ts = d.get("result", {}).get("tools", [])
print("count:", len(ts))
for t in ts[:8]:
    print("-", t["name"])
print("..." if len(ts) > 8 else "")'
```

### `tools/call`

Try `list_rsps` — no-arg, returns the seeded RSPs:

```bash
curl -sS -X POST -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "id":3,
    "params":{"name":"list_rsps","arguments":{}}
  }' \
  http://localhost:4000/mcp
```

Should return a `result.content[0].text` containing the JSON-encoded list of
six RSPs (Wedge-tail, Quokka, Ibis, Taipan, Echidna, Dugong).

## Wiring Claude Code

In any directory, with the server running:

```bash
claude mcp add diffo --transport http http://localhost:4000/mcp
```

This adds an entry to your global `~/.claude.json`. For a project-scoped
config (writes to a `.mcp.json` next to the cwd):

```bash
claude mcp add diffo --transport http -s project http://localhost:4000/mcp
```

After adding, any Claude Code session can call the tools. Try prompts like:

- "list the RSPs"
- "qualify a DSL service for a customer with this location and these parties"
- "build a cable, define it with 60 pairs as copper, then auto-assign a pair to
  the qualified service"
- "show me the path with id X and its assigned ports and cables"

Claude will discover the right tools via `tools/list`, call them with the
arguments inferred from the prompt, and explain the results.

## Wiring Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)
or the equivalent on your OS:

```json
{
  "mcpServers": {
    "diffo": {
      "type": "http",
      "url": "http://localhost:4000/mcp"
    }
  }
}
```

Restart Claude Desktop. The tools appear under the hammer icon in the prompt
input area. Hover any tool to see its description and schema.

## Wiring Cursor / Continue / other MCP clients

Any MCP-aware editor or assistant follows the same shape. Point them at
`http://localhost:4000/mcp` with HTTP transport. Refer to the client's MCP
configuration docs for the exact file/UI path.

## What tools are available

The full list is discoverable via `tools/list` (see above). At a glance:

**Access (~23 tools)**
- DslAccess: read, qualify, qualify_result, design_result
- Shelf: read, build, define, relate, assign_slot
- Card: read, build, define, relate, assign_port (`:assign_port_on_card`)
- Cable: read, build, define, relate, assign_pair
- Path: read, build, define, relate

**Nbn (~37 tools)**
- NbnEthernet, Uni, Avc, Nni: read, build, define, relate (each)
- Ntd: read, build, define, assign_port (`:assign_port_on_ntd`), relate
- Cvc: read, build, define, assign_cvlan, relate
- NniGroup: read, build, define, assign_svlan, relate
- Rsp: inventory (`:list_rsps`), read, build, activate, suspend, deactivate

The tool name in MCP matches the `tools do` declaration in
`lib/access/access.ex` and `lib/nbn/nbn.ex`.

## Adjusting the surface

The router is wired with `tools: true`, which exposes every tool declared on
every domain in the configured `:diffo_example, :ash_domains` list. To narrow
the surface, edit the `forward "/mcp"` block in `lib/nbn/router.ex` and
replace `tools: true` with an explicit list of tool atoms — e.g.
`tools: [:list_rsps, :get_path_by_id, :qualify_dsl]`.

For separate scopes (read-only vs full-surface, public vs authenticated), add
a second `forward "/mcp_admin"` with its own tool list.

## Adding new tools

When you add a new action to a resource, add it to the appropriate domain's
`tools do` block as well. The compile won't catch a missing tool entry; the
action will simply be invisible to MCP clients.

## Authorisation

The current router is unauthenticated — local-dev use case. Tools execute
with no actor, which means:

- Resources with `bypass DiffoExample.Nbn.Checks.NoActor do authorize_if always() end`
  (every NBN resource — see `lib/nbn/rsp_ownership.ex`) execute as a
  bypass — Perentie-internal access.
- Actions without that bypass policy may fail or behave differently with no
  actor.

For multi-tenant or production deployments, add
`AshAuthentication.Strategy.ApiKey.Plug` (or similar) in a pipeline ahead of
the MCP forward, and pass the resolved actor through to the tool calls. The
existing RSP-actor multi-tenancy machinery will then bound what each MCP
client can do based on its principal.

## Troubleshooting

- **`tools/list` returns count: 0** — the `forward "/mcp"` block isn't passing
  `tools: true` (or a tool list) and `otp_app: :diffo_example`. Check
  `lib/nbn/router.ex`.
- **`Connection refused` on `http://localhost:4000/mcp`** — the server isn't
  running, or it crashed at startup. Restart with `MIX_ENV=dev mix run --no-halt`
  and watch the startup logs.
- **A specific tool call errors with policy/auth message** — the action requires
  an actor that the unauthenticated MCP request can't supply. Either run with
  `MIX_ENV=test` (some test bypasses), use a tool that doesn't need an actor,
  or wire up auth as above.
- **`tools/call` works in curl but Claude can't find the tool** — restart the
  Claude client after adding the MCP server. Many MCP clients only refresh
  the tools list on session start.
- **Schema mismatches in tool args** — `inputSchema` in `tools/list` is the
  source of truth. The Ash action's arguments (and their `public?` and types)
  determine the schema; private arguments aren't exposed.

<!--
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Agents working in this repo

Notes for AI assistants (Claude Code, Cursor, Continue, etc.) and humans pairing with them.

## Keep `tools do` aligned with `define`d actions

Each Ash domain in this repo (`DiffoExample.Access`, `DiffoExample.Nbn`) declares two parallel lists:

1. **`resources do ... resource X do define :name, action: :foo end end`** — the code-interface surface, generating `MyDomain.name/...` functions for Elixir callers.
2. **`tools do tool :name, X, :foo end`** — the MCP surface, exposing the same actions to AI agents via [`ash_ai`](https://hexdocs.pm/ash_ai).

**When you add a new action to a resource, add it to BOTH places.** Forgetting to add the `tool` entry leaves the action invisible to MCP clients — the test suite won't catch it, the code compiles, the action works for Elixir callers, and the AI silently can't reach it.

The convention is:

- One `tool` entry per `define`-d action.
- Tool name matches the code-interface name where possible (e.g. `define :build_cable` ↔ `tool :build_cable, Cable, :build`). Disambiguate with a suffix where two resources have actions of the same name (e.g. `tool :assign_port_on_card` and `tool :assign_port_on_ntd`).
- Read actions exposed as their natural read names (`tool :get_cable_by_id, Cable, :read`).

## Why the discipline

Tool-via-existing-action is the WWZD-shaped pattern: authorisation, validation, after-action choreography, multi-tenancy, polymorphism — all inherited from the action without writing AI-specific logic. The AI gets the same access an RSP-actor consumer has, no more and no less. That property only holds if every action the AI should be able to reach is declared as a tool.

## When NOT to add a tool

- **Internal-only actions** that no consumer (Elixir, HTTP, MCP) should call directly. These typically don't have a `define` either.
- **Provider primitives** (`Diffo.Provider.create_party`, `Diffo.Provider.create_place`) — deliberately not exposed via Access/Nbn MCP. When Access/Nbn grow their own party/place relationship-management actions, expose those instead, and let authorisation gate what each actor can do.
- **Duplicate `define`s wrapping the same action** — e.g. `define :get_rsp_by_epid, action: :read, get_by: :id` and `define :get_rsp_by_short_name, action: :read, get_by: :short_name` both wrap the `:read` action with different filters. One tool (`tool :get_rsp_by_epid, Rsp, :read`) covers both — the AI can supply the filter shape it needs via tool arguments. The code-interface defines are an Elixir convenience; the tool exposes the underlying action.

## Where this matters most

If you're modifying:

- A `*.ex` file under `lib/access/resources/`, `lib/access/services/`, or `lib/nbn/resources/` that adds/renames a `define` in its domain — also touch `lib/access/access.ex` or `lib/nbn/nbn.ex` and update the `tools do` block.
- The `tools do` block itself — make sure the resource module is aliased at the top of the domain file.

## Quick check

After changes, count alignment:

```bash
# tools declared
grep -c "tool :" lib/access/access.ex lib/nbn/nbn.ex

# actions code-interface-defined
grep -c "define :" lib/access/access.ex lib/nbn/nbn.ex
```

The two should match (modulo intentional exclusions).

## Before you commit

Two checks before any commit, every commit:

```bash
mix format           # auto-format every changed file to project style
reuse lint           # ensure every file has SPDX-FileCopyrightText + SPDX-License-Identifier
```

New `.ex` / `.exs` files start with a comment header matching the existing
files (see `lib/diffo_example/util.ex` for the canonical form). New markdown
files use an HTML-comment variant (see `README.md`). `reuse lint` will tell
you which files are missing copyright/license info; if you've created a
new file and haven't added the header, this is the place to catch it.

Forgetting either is the easiest way to introduce CI noise the reviewer
has to clean up. Save them both the time.

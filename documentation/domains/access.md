<!--
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# The Access Domain

Access is a small **DSL service** domain — a single fictional telco delivering broadband over copper to its own customers. It models the service the telco sells (`DslAccess`) and the physical infrastructure it runs on (`Shelf`, `Card`, `Path`, `Cable`).

Use it as the warm-up. The pattern is small enough to hold in your head and rich enough to show every diffo modelling primitive you'll need. NBN (the second example) revisits the same primitives with multi-tenancy and a much longer delivery chain.

## What's in here

| Kind | Resource | Plays the role of |
|---|---|---|
| Service | `DslAccess` | the broadband product the telco sells to a subscriber |
| Resource | `Shelf` | a DSLAM frame at the exchange — slots for line cards |
| Resource | `Card` | a line card in a shelf slot — ports for customer paths |
| Resource | `Path` | the physical/logical access path from the exchange to the customer |
| Resource | `Cable` | a copper cable — carries pairs assigned to paths |

`Shelf`, `Card`, and `Cable` each declare a **pool**: `:slots`, `:ports`, `:pairs`. Other resources consume those pools by being assigned a value — a card takes a slot from a shelf, a path takes a port from a card and a pair from a cable.

## Topology

The downstream view (the assignment direction) is a stack:

```
Shelf (slots pool) ─── Card (ports pool) ─── Path
                                              │
                                      Cable (pairs pool)
```

A `Card` is **assigned a slot** from its `Shelf`; a `Path` is **assigned a port** from its `Card` and **assigned pairs** from `Cable`s along the route. The consuming resource names its upstream by the role it plays — `:shelf`, `:card`, `:cable` — and that name (`alias`) sits on the assignment record so the relationship can be walked from either side.

The `DslAccess` service stands in front of the resources. It's the *what we sell*; the resources are the *what makes it work*.

## Inheritance — bringing upstream context up

Every consumer can read characteristics from what it's part of, without copying:

- `Card.shelf` brings up the **`ShelfCharacteristic`** value of the shelf this card sits in (single-hop via `:shelf`).
- `Path.card` brings up the card it's plugged into (single-hop via `:card`).
- `Path.shelf` brings up the shelf — two-hop via `[:card, :shelf]`.
- `Shelf.cards` brings up every card sitting in a slot (reverse direction).

These are derived live from the assignment graph; nothing is duplicated.

## Service lifecycle

`DslAccess` is a TMF service with a small state machine:

```
:initial ── qualify_dsl_result ──▶ :feasibilityChecked ── design_dsl_result ──▶ :reserved
```

Each transition is an Ash action. Each action shapes the JSON output — the service's `state` field reflects where you are.

## Scenario walk-through

The standard provisioning flow — set up the infrastructure, then qualify and design a service for a subscriber:

```elixir
# 1. Exchange has a shelf with a slots pool
{:ok, shelf} = Access.build_shelf!(%{name: "QDONC-0001", places: [exchange]})
Access.define_shelf!(shelf, %{
  characteristic_value_updates: [
    shelf: [device_name: "QDONC-0001", family: :ISAM, model: "ISAM7330", technology: :DSLAM],
    slots: [first: 1, last: 10, assignable_type: "LineCard"]
  ]
})

# 2. A line card consumes a slot from the shelf — it names its upstream Shelf :shelf
{:ok, card} = Access.build_card!(%{name: "line card 1"})
Access.define_card!(card, %{
  characteristic_value_updates: [
    card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
    ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
  ]
})
Access.assign_slot!(shelf, %{
  assignment: %Assignment{assignee_id: card.id, alias: :shelf, operation: :auto_assign}
})

# 3. The subscriber's path through copper to the exchange
{:ok, path} = Access.build_path!(%{name: "82 Rathmullen", places: [customer_site, exchange]})
Access.define_path!(path, %{
  characteristic_value_updates: [path: [technology: :copper, sections: 5]]
})

# 4. Cables along the route — each one assigns a pair to the path
Enum.each(cables, fn cable ->
  Access.assign_pair!(cable, %{
    assignment: %Assignment{assignee_id: path.id, alias: :cable, operation: :auto_assign}
  })
end)

# 5. The card assigns a port to the path — the path names its upstream Card :card
Access.assign_port!(card, %{
  assignment: %Assignment{assignee_id: path.id, alias: :card, operation: :auto_assign}
})

# 6. Now sell the service. Qualify first (do we have feasibility at this address?)
{:ok, dsl} = Access.qualify_dsl(%{parties: [customer, reseller], places: [customer_site]})
{:ok, dsl} = Access.qualify_dsl_result(dsl, %{
  service_operating_status: :feasible,
  places: [esa]
})

# 7. Design — set the service's characteristics. State goes to :reserved.
{:ok, dsl} = Access.design_dsl_result(dsl, %{
  characteristic_value_updates: [
    dslam: [device_name: "QDONC0001", model: "ISAM7330"],
    aggregate_interface: [interface_name: "eth0", svlan_id: 3108],
    circuit: [cvlan_id: 82],
    line: [slot: 10, port: 5]
  ]
})
```

Read the path's brought-up context to see inheritance working live:

```elixir
{:ok, path} = Access.get_path_by_id(path.id, load: [:card, :shelf, :port])

path.card    # ⇒ [%CardCharacteristic.Value{family: :ISAM, model: "EBLT48", ...}]
path.shelf   # ⇒ [%ShelfCharacteristic.Value{device_name: "QDONC-0001", ...}] (two-hop)
path.port    # ⇒ [1]  (the port number this path was assigned)
```

## Domain API reference

See [_access_api.md](_access_api.md) for the auto-generated table of every `code_interface` function on `DiffoExample.Access` — function name, action, arguments, purpose. Regenerated with `mix gen.api_docs`.

## What's underneath?

You've been using diffo's Provider primitives the whole time — **specifications**, **typed characteristics**, **pools**, **assignments**, **relationships**, **state machines**, and the **TMF JSON encoding** that surfaces them. None of those are bespoke to Access; they all come from the [Provider domain](provider.md), which is where to look next once you've internalised this scenario.

For a runnable walk-through of the scenario, open [diffo_example_access.livemd](diffo_example_access.livemd) in Livebook.

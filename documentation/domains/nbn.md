<!--
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# The NBN Domain

NBN is a fictional, simplified take on Australia's wholesale broadband network. Where [Access](access.md) was a single telco running its own DSL service, **NBN is wholesale** — a single physical network shared by many Retail Service Providers (RSPs) who in turn sell to end customers. That changes the modelling job in two ways:

- **Multi-tenancy** — every resource is owned by an RSP and policy-scoped to its owner.
- **Longer delivery chain** — the customer's broadband signal hops through more layers, which is what the inheritance and metrics patterns from issue [#49](https://github.com/diffo-dev/diffo_example/issues/49) are designed for.

NBN is the second example for that reason. Do [Access](access.md) first — same primitives, simpler stage.

## The Retail Service Providers

The example ships with seven fictional RSPs as their spirit animals — the cast of Australian wildlife competing for niches in the network:

| RSP                | Spirit Animal      | Inspiration                                                                                                              |
| ------------------ | ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| Wedge-tail Telecom | Wedge-tailed Eagle | Australia's apex aerial predator — dominant, territorial, commands every landscape it surveys                            |
| Quokka Connect     | Quokka             | Famously friendly, genuinely Australian, radiates good energy — operates in WA under bilateral agreement                 |
| Ibis Telecom       | White Ibis         | Beloved in spite of its reputation, scrappy, surprisingly capable                                                        |
| Taipan Group       | Taipan             | Carries the TPG initials; fast, precise, not to be underestimated                                                        |
| Echidna Networks   | Echidna            | Prickly on the surface, uniquely capable beneath it                                                                      |
| Dugong Digital     | Dugong             | Slow and steady, but still very much alive                                                                               |
| Lyrebird           | Lyrebird           | Mimics everything, loops back on itself, endlessly clever                                                                |

`Rsp` is modelled as a Party (using diffo's `BaseParty` fragment), with a four-digit EPID as its id. Every NBN resource is stamped with the owning RSP's EPID at creation, and policies scope reads, updates, and destroys to the owner.

## What's in here

### Service

| Resource | Plays the role of |
| --- | --- |
| `NbnEthernet` (PRI) | the wholesale broadband product an RSP buys from NBN for one customer site |

### Resources

| Resource | Plays the role of | Pool |
| --- | --- | --- |
| `Uni` | the customer-side network interface | — |
| `Avc` | dedicated Access Virtual Circuit (the customer's traffic) | — |
| `Ntd` | Network Termination Device installed at the premises | `:ports` |
| `Cvc` | Connectivity Virtual Circuit (aggregates many AVCs on a pipe) | `:cvlans` |
| `NniGroup` | grouping of NNIs at a single Point of Interconnect | `:svlans` |
| `Nni` | physical Network-to-Network Interface at the POI | — |

## Topology

Two views, both useful.

### The provisioning view — what's assigned to what

```
NniGroup (svlans) ──── CVC (cvlans) ──── AVC
                                          │
                                       NbnEthernet (PRI) ──── UNI ──── NTD (ports)
                                                                 ▲       │
                                                                 └───────┘
```

`NniGroup` contains many `Nni`s (low-cardinality `:contains` relationship) and assigns one `:svlan` to each `Cvc`. Each `Cvc` assigns ~4000 `:cvlans` to `Avc`s. Each `Ntd` assigns one of its few `:ports` to a `Uni`. The `NbnEthernet` (PRI) owns one `Avc` and one `Uni` per customer site via two `:owns` relationships aliased `:circuit` (for the AVC) and `:port` (for the UNI).

### The consumer's view — what each thing is part of

Each consumer names its upstream by the role it plays:

| Consumer | Upstream | Consumer's `alias` for it |
| --- | --- | --- |
| `Avc`     | `Cvc`      | `:cvc`       |
| `Cvc`     | `NniGroup` | `:nni_group` |
| `Uni`     | `Ntd`      | `:ntd`       |
| `NbnEthernet` | `Avc`  | `:circuit`   |
| `NbnEthernet` | `Uni`  | `:port`      |

These aliases sit on the assignment / relationship records. They're what the inheritance walks follow. See [provider.md](provider.md) for what alias means and why it lands on the consumer's side.

## Two characteristics per resource

A pattern that emerges at NBN's cardinality: each resource carries **two** typed characteristics.

- A **named characteristic** (`cvc`, `nni_group`, `avc`, …) — identity and context that *can* be inherited downstream.
- A **`metrics` characteristic** — local KPIs (counts, totals, utilization) that **must not** be inherited. Downstream consumers want context, not their parent's sibling-count.

| Resource | Named | Metrics |
| --- | --- | --- |
| `Avc`         | `avc`         | — (leaf) |
| `Cvc`         | `cvc`         | `metrics` — `avcs_count`, `avcs_total_bandwidth` |
| `NniGroup`    | `nni_group`   | `metrics` — `cvcs_count`/`cvcs_total_bandwidth`, `nnis_count`/`nnis_total_bandwidth`, `utilization` |
| `Ntd`         | `ntd`         | — (low N) |
| `Uni`         | `uni`         | — (leaf) |
| `NbnEthernet` | `pri`         | — (the service is a leaf) |

The cardinality on the inverse direction is what drives this. A CVC has ~4000 AVCs — listing them all as `avcs[]` would explode the JSON. A summary keeps the KPIs without the explosion. Where cardinality is low (an `NniGroup` has a handful of NNIs, an `Ntd` has a handful of UNIs) you can have both — the NNIs surface as a `:contains` relationship and as an aggregate.

## Inheritance — what each consumer can bring up

Forward, via assignment (singular — each consumer has one upstream):

- `Avc.cvc` — single-hop via `:cvc`
- `Avc.nni_group` — two-hop via `[:cvc, :nni_group]`
- `Cvc.nni_group` — single-hop via `:nni_group`

Forward, via relationship (singular):

- `NbnEthernet.avc` — single-hop via the `:circuit` owns relationship
- `NbnEthernet.uni` — single-hop via the `:port` owns relationship
- `NbnEthernet.cvc` — two-hop: `:circuit` owns relationship, then `:cvc` assignment back to the CVC
- `NbnEthernet.ntd` — two-hop: `:port` owns relationship, then `:ntd` assignment back to the NTD

Reverse, low-N (returns a list):

- `NniGroup.nnis` — every NNI this group contains, via `:contains`

All of these return the typed `<Characteristic>.Value{}` struct (the inner payload), not the wrapping record — same shape that surfaces in TMF JSON's `value` field.

## Scenario walk-through

The provisioning flow when an RSP sells an NBN Ethernet access to a subscriber:

```elixir
# Acting as one RSP (after Initializer.init seeded them)
actor = Nbn.list_rsps!() |> Enum.find(&(&1.short_name == :quokka))

# 1. Shareable infrastructure (built once per RSP per POI)
{:ok, nni_group} = Nbn.build_nni_group(%{}, actor: actor)
{:ok, nni_group} = Nbn.define_nni_group(nni_group, %{
  characteristic_value_updates: [
    nni_group: [group_name: "SYD-POI-01", location: "Sydney Olympic Park"],
    svlans: [first: 1, last: 4000, assignable_type: "svlan"]
  ]
}, actor: actor)

# 2. CVC takes an svlan from the NNI Group, naming the upstream :nni_group
{:ok, cvc} = Nbn.build_cvc(%{}, actor: actor)
{:ok, cvc} = Nbn.define_cvc(cvc, %{
  characteristic_value_updates: [
    cvc: [bandwidth: 1000],
    cvlans: [first: 1, last: 4000, assignable_type: "cvlan"]
  ]
}, actor: actor)
{:ok, _nni_group} = Nbn.assign_svlan(nni_group, %{
  assignment: %Assignment{assignee_id: cvc.id, alias: :nni_group, operation: :auto_assign}
}, actor: actor)

# 3. Per-customer infrastructure — NTD at the premises, UNI on the NTD
{:ok, ntd} = Nbn.build_ntd(%{})  # NBN-managed, no RSP actor
{:ok, ntd} = Nbn.define_ntd(ntd, %{
  characteristic_value_updates: [
    ntd: [model: "Sercomm CG4000A", technology: :FTTP],
    ports: [first: 1, last: 4, assignable_type: "port"]
  ]
})
{:ok, uni} = Nbn.build_uni(%{})
{:ok, _ntd} = Nbn.assign_port(ntd, %{
  assignment: %Assignment{assignee_id: uni.id, alias: :ntd, operation: :auto_assign}
})

# 4. AVC takes a cvlan from the CVC, naming the upstream :cvc
{:ok, avc} = Nbn.build_avc(%{}, actor: actor)
{:ok, _avc} = Nbn.define_avc(avc, %{
  characteristic_value_updates: [avc: [bandwidth_profile: :home_fast]]
}, actor: actor)
{:ok, _cvc} = Nbn.assign_cvlan(cvc, %{
  assignment: %Assignment{assignee_id: avc.id, alias: :cvc, operation: :auto_assign}
}, actor: actor)

# 5. The PRI (NbnEthernet) owns the AVC :circuit and the UNI :port
{:ok, pri} = Nbn.build_nbn_ethernet(%{}, actor: actor)
{:ok, _pri} = Nbn.relate_nbn_ethernet(pri, %{
  relationships: [
    %Relationship{id: avc.id, direction: :forward, type: :owns, alias: :circuit},
    %Relationship{id: uni.id, direction: :forward, type: :owns, alias: :port}
  ]
}, actor: actor)
```

Then read the full chain — every brought-up characteristic resolves through the assignment and relationship graph:

```elixir
{:ok, pri} = Nbn.get_nbn_ethernet_by_id(pri.id, load: [:avc, :uni, :cvc, :ntd], actor: actor)

%{
  avc: pri.avc,    # %AvcCharacteristic.Value{bandwidth_profile: :home_fast}
  uni: pri.uni,    # %UniCharacteristic.Value{...}
  cvc: pri.cvc,    # %CvcCharacteristic.Value{bandwidth: 1000} (two-hop)
  ntd: pri.ntd     # %NtdCharacteristic.Value{technology: :FTTP} (two-hop)
}
```

And read the metrics — the CVC's view of its AVCs, the NNI Group's view of its CVCs and NNIs:

```elixir
DiffoExample.Nbn.CvcMetrics
|> Ash.Query.filter_input(instance_id: cvc.id)
|> Ash.Query.load(:value)
|> Ash.read_one!()
# %CvcMetrics.Value{avcs_count: 1, avcs_total_bandwidth: 500}
```

## Domain API reference

See [_nbn_api.md](_nbn_api.md) for the auto-generated table of every `code_interface` function on `DiffoExample.Nbn` — function name, action, arguments, purpose. Regenerated with `mix gen.api_docs`.

## What next?

You've seen the wholesale story — multi-tenant ownership, longer delivery chain, named-vs-metrics characteristics, full inheritance with the alias convention. NBN is a deliberately small slice of the real wholesale problem; the next layer down (NBN's own internal `fibreAccess`, `aggregation`, switching) lives in separate domains, modelled or not by their respective owners. The contract between them is the same shape diffo uses internally — expectations and action APIs — which at organisational boundaries aligns with **NaaS** (Network as a Service, the TM Forum standard for inter-provider interfaces).

For a runnable walk-through of the scenario, open [diffo_example_nbn.livemd](diffo_example_nbn.livemd) in Livebook.

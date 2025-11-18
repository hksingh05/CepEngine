# CepEngine

Complex Event Processing (CEP) system for market data written in q (kdb+). This repository includes a tickerplant that generates mock market snapshots and a CEP engine that loads modular components (schemas, utilities, calculations, core logic, and a demo/data feed) and demonstrates processing, subscription handling, and simple analytics.

---

## Table of contents

- Features
- Requirements
- Quickstart
- Tickerplant (publisher)
  - Configuration
  - Snapshot schemas
  - Subscription & publish API
  - Start / init
- CEP engine (subscriber/processor)
  - Modules loaded
  - Common commands / helpers
- Example workflow
- API / Table schemas
- Tests
- Development & extending
- Troubleshooting
- Contributing
- License

---

## Features

- Mock tickerplant that publishes Snap_1 / Snap_60 / Snap_3600 tables on timers
- CEP engine that loads modular q scripts (schema, utils, calculations, core, data_feed)
- Demonstration runner and tests
- Simple subscription API for clients/CEP to subscribe to snapshots
- Multi-frequency publishing (1s, 60s, 3600s)

---

## Requirements

- kdb+ / q (compatible with the q code in this repo)
- Local network access between processes (default examples use `localhost:5010`)

---

## Quickstart

Open two terminals.

1. Start tickerplant (publisher):
```
q tickerplant.q -p 5010
```

2. Start CEP engine:
```
q cep.q
```

When cep.q finishes loading, it prints:
- "=== CEP System Ready"
- Helpful commands such as `.cep.connectToTP[]`, `.cep.subscribeToTP[]`, `.cep.addStatsReq[req]`, and test instructions.

---

## Tickerplant (publisher)

The publisher is implemented in `tickerplant.q`. It generates and publishes market snapshots for a configured symbol list.

### Configuration
From tickerplant.q:
```q
SYMS:`GOOG`META`TSLA`AAPL`MSFT;
BASEPRICES:150 320 200 180 380f;
```

### Snapshot schemas
Tickerplant defines three snapshot tables:
```q
Snap_1:   ([] sym:`$(); SnapTimeUtc:`timestamp$(); BidPx:`float$(); BidQty:`long$(); AskPx:`float$(); AskQty:`long$(); TradePx:`float$(); TradeQty:`long$());
Snap_60:  (same schema)
Snap_3600: (same schema)
```

### Subscription & publish API
- `sub:{[tbl;syms] ... }` — subscribe: registers a client handle for a table and returns schema (used by clients to subscribe).
- `publish:{[tbl;data] ... }` — publish: sends `upd` messages to all registered subscriber handles.

Example: subscribe from a q client (or CEP):
```q
h:hopen `:localhost:5010
h(".tp.sub"; `Snap_1; `; h)
```

Tickerplant logs subscription activity, e.g. "Added handle <n> to Snap_1 subscribers".

### Start / init
Tickerplant auto-initializes on load but can be started explicitly:
```q
.tp.init[]    / initializes and starts timers
```
It uses `.z.ts` timer to:
- publish 1-second snapshots every second
- publish aggregated 60s snapshots every 60 ticks
- publish aggregated 3600s snapshots every 3600 ticks

Log examples:
- "Tickerplant loaded. Call .tp.init[] to start."
- "Timers started: 1sec"

---

## CEP engine (subscriber/processor)

`cep.q` loads modules and initializes CEP. It then runs a demo automatically by default.

### Modules loaded
cep.q loads these modular scripts (under `src/`):
- `src/schema.q`
- `src/utils.q`
- `src/calculations.q`
- `src/core.q`
- `src/data_feed.q`

### Common commands / helpers
cep.q prints useful commands after startup. Typical helpers include:
- `.cep.connectToTP[]` — connect CEP to tickerplant (helper in core module)
- `.cep.subscribeToTP[]` — subscribe to TP tables (helper)
- `.cep.addStatsReq[req]` — add a manual stats request
- `.cep.runDemo[]` — run the bundled demo
- Inspect internal tables:
  - `.cep.Stats` — results/statistics table
  - `.cep._PendingStatsReq` — pending requests

Run tests:
```q
\l tests/test_cep.q
.Test.runAllTests[]
```

---

## Example workflow

1. Start tickerplant:
```bash
q tickerplant.q -p 5010
```

2. Start CEP:
```bash
q cep.q
```

3. From CEP process (or another client), connect and subscribe:
```q
/ CEP helper (if available)
.cep.connectToTP[]
.cep.subscribeToTP[]   / subscribe to configured tables

/ or manually from any q client
h:hopen `:localhost:5010
h(".tp.sub"; `Snap_1; `; h)
```

4. Observe:
- In tickerplant process: tables `.tp.Snap_1`, `.tp.Snap_60`, `.tp.Snap_3600` are upserted locally.
- In CEP process: `.cep.Stats` receives processed results (depending on calculations module).

5. Run demo or tests:
```q
.cep.runDemo[]
\l tests/test_cep.q
.Test.runAllTests[]
```

---

## API / Table schemas

Snap tables (Snap_1 / Snap_60 / Snap_3600)
- Columns:
  - `sym` : symbol
  - `SnapTimeUtc` : timestamp
  - `BidPx` : float
  - `BidQty` : long
  - `AskPx` : float
  - `AskQty` : long
  - `TradePx` : float
  - `TradeQty` : long

CEP internal tables (examples):
- `.cep.Stats` — statistics/results produced by CEP calculations
- `.cep._PendingStatsReq` — pending stats requests

---

## Tests

- Tests are located at: `tests/test_cep.q`  
- Run them:
```q
\l tests/test_cep.q
.Test.runAllTests[]
```

---

## Development & extending

- Add/modify modules under `src/`:
  - `schema.q` — data schemas
  - `utils.q` — helper utilities
  - `calculations.q` — metrics and calculations
  - `core.q` — core CEP functions & API
  - `data_feed.q` — input/data feed handlers
- Modify `tickerplant.q` to change `SYMS` and `BASEPRICES` or alter publishing logic.
- Keep tests in sync and add tests for new features in `tests/`.

---

## Troubleshooting

- Module load failures: cep.q prints errors while loading modules and exits on failures. Check printed error message to find failing file.
- Connectivity: ensure tickerplant is reachable at the host/port used by CEP (default `localhost:5010`).
- No updates: verify client handle registration — subscriber must register with `.tp.sub` (or via helper) so tickerplant will publish updates to them.

---

## Contributing

- Open issues and pull requests are welcome.
- Add tests for new behavior and follow the existing module structure under `src/`.

---

## License

No license file is included in the repository. Add a license (e.g., MIT or Apache-2.0) if you want to permit reuse. I can generate an MIT LICENSE text for you if you want.

---

If you want, I can:
- Insert concrete snippets from modules under `src/` into this README (I can extract and include representative functions),
- Add an MIT LICENSE block and a short badge header,
- Produce a more compact README variant optimized for repository preview.

Which option do you prefer?
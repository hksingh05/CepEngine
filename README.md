# CepEngine

Complex Event Processing (CEP) system for market data written in q (kdb+). This repository includes a tickerplant that generates mock market snapshots for snap data and a CEP engine that loads modular components (schemas, utilities, calculations, core logic, and a demo/data feed) and demonstrates processing, subscription handling, and simple analytics.

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
- Future Performance Tips

---

## Features

- Mock tickerplant that publishes Snap_1 / Snap_60 / Snap_3600 tables on timers
- CEP engine that loads modular q scripts (schema, utils, calculations, core, data_feed)
- Demonstration runner
- Simple subscription API for clients/CEP to subscribe to snapshots
- Multi-frequency publishing for snap tables(1s, 60s, 3600s)
- Calculate analytics in requests table and store results in Stats table and delete request once done.

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

## Testing Evidence:
 <img width="1527" height="471" alt="image" src="https://github.com/user-attachments/assets/f5964a5b-0d1b-4a2f-b0bc-678e51a337bc" />



## Further Performance Tips in production
## Code level
- Run Cep and tp processes on same machine and use unix socket to connect rather than tcp/IP for faster messages publishing.
- As of now, I am persisting the tables in tp for testing purpose. We should rather avoid persisting data  in tp memory.
- For the Snap Cache tables persisting in cep services, not sure how long we should store data. Based on user requirements, can delete the old data from snap tables if not required.
- As of now, processing the snap tables on each upd. For better performance, create a separate processing handler which will run on timer basis to process the snap data.
  
 ## Hardware level
 - 10GbE or InfiniBand networking
 - NUMA-aware CPU pinning using **numactl** at process startup or using **taskset** for cpu affinity.

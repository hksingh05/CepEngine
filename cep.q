/ CEP (Complex Event Processing) System for Market Data
/ Usage:
/ With tickerplant: q tickerplant.q -p 5010  (in separate terminal)
/ q cep.q (in other terminal)
\d .cep
/ ============================================================================
/ MODULE LOADING
/ ============================================================================

-1 "Loading CEP System modules...";


/ Load schema definitions
-1 "  Loading schemas...";
@[system;"l src/schema.q";{-1"ERROR loading src/schema.q: ",x; exit 1}];

/ Load utilities
-1 "  Loading utilities...";
@[system;"l src/utils.q";{-1"ERROR loading src/utils.q: ",x; exit 1}];

/ Load calculation engine
-1 "  Loading calculations...";
@[system;"l src/calculations.q";{-1"ERROR loading src/calculations.q: ",x; exit 1}];

/ Load core CEP functionality
-1 "  Loading core...";
@[system;"l src/core.q";{-1"ERROR loading src/core.q: ",x; exit 1}];

/ Load data feed and demo
-1 "  Loading data feed...";
@[system;"l src/data_feed.q";{-1"ERROR loading src/data_feed.q: ",x; exit 1}];

-1 "All modules loaded successfully.\n";

/ ============================================================================
/ STARTUP
/ ============================================================================

/ Initialize system
@[value;".cep.init[]";{-1"ERROR in init: ",x}];

/ Run demonstration automatically
@[value;".cep.runDemo[]";{-1"ERROR in runDemo: ",x}];

\d .

-1 "\n=== CEP System Ready ===";
-1 "Inspect tables: .cep.Stats, .cep._PendingStatsReq";
-1 "Manual testing: .cep.addStatsReq[req]";
-1 "Tickerplant: .cep.connectToTP[], .cep.subscribeToTP[]";
-1 "Run tests: \\l tests/test_cep.q then .Test.runAllTests[]";

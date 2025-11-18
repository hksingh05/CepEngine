/ Tickerplant for CEP System
/ Generates and publishes market data snapshots

\d .tp

/ ============================================================================
/ CONFIGURATION
/ ============================================================================

/ Symbols to generate data for
SYMS:`GOOG`META`TSLA`AAPL`MSFT;

/ Base prices for each symbol
BASEPRICES:150 320 200 180 380f;

/ ============================================================================
/ SNAP TABLE DEFINITIONS
/ ============================================================================

Snap_1:([]sym:`$(); SnapTimeUtc:`timestamp$(); BidPx:`float$(); BidQty:`long$(); AskPx:`float$(); AskQty:`long$(); TradePx:`float$(); TradeQty:`long$());
Snap_60:([]sym:`$(); SnapTimeUtc:`timestamp$(); BidPx:`float$(); BidQty:`long$(); AskPx:`float$(); AskQty:`long$(); TradePx:`float$(); TradeQty:`long$());
Snap_3600:([]sym:`$(); SnapTimeUtc:`timestamp$(); BidPx:`float$(); BidQty:`long$(); AskPx:`float$(); AskQty:`long$(); TradePx:`float$(); TradeQty:`long$());

/ ============================================================================
/ SUBSCRIPTION MANAGEMENT
/ ============================================================================

/ Subscriber table -> list of handles
subscribers:(enlist`)!enlist();

/ Subscribe function
sub:{[tbl;syms]
    -1"client handle ",.Q.s1 .z.w;
    -1"Subscription request: table=",string[tbl]," syms=",(.Q.s1 syms);
     handle:.z.w;
    / Add handle to subscribers for this table
    if[not tbl in key subscribers; subscribers[tbl]:()];
    if[not handle in subscribers[tbl];
        subscribers[tbl],:handle;
        -1"Added handle ",string[handle]," to ",string[tbl]," subscribers";
    ];

    / Return schema for the table
    $[tbl=`Snap_1; (Snap_1;`Snap_1);
      tbl=`Snap_60; (Snap_60;`Snap_60);
      tbl=`Snap_3600; (Snap_3600;`Snap_3600);
      '`unknown_table]
 };

/ Publish data to subscribers
publish:{[tbl;data]
    if[tbl in key subscribers;
        handles:subscribers[tbl];
        handle:first handles;
        if[count handle;
            / Send to subscriber
           @[(neg handle);(`.cep.upd;tbl;data);{-1"Error publishing to handle ",string[handle]}];
        ];
    ];
 };

/ ============================================================================
/ MOCK DATA GENERATION
/ ============================================================================

/ Generate mock snap data for one symbol
generateSnapForSym:{[sym;basePrice]
    / Add some random volatility
    volatility:(rand 2.0) - 1.0;  / +/- 1
    bidPx:basePrice + volatility;
    spread:0.01 + rand 0.05;       / 0.01 to 0.06 spread
    askPx:bidPx + spread;
    tradePx:bidPx + (rand spread); / Trade within spread

    ([]sym:enlist sym;
      SnapTimeUtc:enlist .z.p;
      BidPx:enlist bidPx;
      BidQty:enlist 100*1+rand 10;
      AskPx:enlist askPx;
      AskQty:enlist 100*1+rand 10;
      TradePx:enlist tradePx;
      TradeQty:enlist 100*1+rand 20)
 };

/ Generate snaps for all symbols
generateSnaps:{[]
    snapData:raze .tp.generateSnapForSym'[SYMS;BASEPRICES];
    snapData
 };;

/ ============================================================================
/ PUBLISHING TIMERS
/ ============================================================================

/ Publish snaps for a given frequency
publishSnap:{[freq]
    data:generateSnaps[];
    / Determine table name based on frequency
    tbl:`$"Snap_",string freq;
    / Store locally
    (` sv `.tp,tbl) upsert data;
    / Publish to subscribers
    .tp.publish[tbl;data];
    -1 string[.z.t]," Published ",string[count data]," rows to ",string tbl;
 }

/ ============================================================================
/ TIMER SETUP
/ ============================================================================

startTimers:{[]
    -1"Starting publishing timers...";

    / Initialize counters for multi-frequency publishing
    snap60Counter::0;
    snap3600Counter::0;

    / Timer
    .z.ts:{
        .tp.publishSnap[1];

        / Check if 60 seconds elapsed (60 ticks of 1 second)
        snap60Counter+:1;
        if[snap60Counter>=60;
            .tp.publishSnap[60];
            snap60Counter::0;
        ];

        / Check if 3600 seconds elapsed (3600 ticks of 1 second)
        snap3600Counter+:1;
        if[snap3600Counter>=3600;
            .tp.publishSnap[3600];
            snap3600Counter::0;
        ];
    };

    / Start 1-second timer
    system"t 1000";  / 1000ms = 1 second

    -1"Timers started: 1sec";
 };

/ ============================================================================
/ INITIALIZATION
/ ============================================================================

init:{[]
    -1"\n=== Tickerplant Initialization ===";
    -1"Symbols: ",.Q.s1 SYMS;
    -1"Base Prices: ",.Q.s1 BASEPRICES;
    -1"\nAvailable tables:";
    -1"  Snap_1 (1-second frequency)";
    -1"  Snap_60 (60-second frequency)";
    -1"  Snap_3600 (3600-second frequency)";
    -1"\nTo subscribe from CEP:";
    -1"  h:hopen `:localhost:5010";
    -1"  h(\".tp.sub\";`Snap_1;`;h)";
    -1"\nStarting data generation...";
    startTimers[];
 };

\d .

/ ============================================================================
/ STARTUP
/ ============================================================================

-1"\nTickerplant loaded. Call .tp.init[] to start.";

/ Auto-initialize
@[value;".tp.init[]";{-1"ERROR in init: ",x}];

-1"\n=== Tickerplant Ready ===";
-1"Generating and publishing mock data on timers";
-1"Waiting for CEP subscriptions...";

/ Data Feed and Mock Data Generation
/ CEP System - Data Feed Module

\d .cep

/ ============================================================================
/ DEMONSTRATION DRIVER
/ ============================================================================

runDemo:{[]
    -1 "=== CEP System Demonstration ===\n";
    
    / Check if connected to tickerplant
    if[not null .cep.tpHandle;
        -1 "Running in TICKERPLANT mode";
        -1 "Data will be received from tickerplant at ",(.Q.s1 .cep.config.tickerplant.host),(":"),(.Q.s1 .cep.config.tickerplant.port);
        -1 "CEP is subscribed and waiting for data...";
        -1 "\nNote: Make sure tickerplant is running: q tickerplant.q -p 5010";
        .cep.runDemoWithTP[];
        :();
    ];
 }

/ Demo with tickerplant connection
runDemoWithTP:{[]
    / Current time for demo
    startTime:.z.p;
    
    -1 "\n1. Creating sample requests...";
    -1 "Requests will be completed as tickerplant publishes data\n";
    
    / Request 1: 1-second snaps for 1 minute window (GOOG, TSLA)
     req1:([] 
        Id:1?0Ng ;
        SnapFreq:enlist 1;           
        StartTimeUtc:enlist startTime;           
        EndTimeUtc:enlist startTime + 0D00:01:00;           
        StatsOverSnaps:enlist ([]Operator:`LAST`AVG; Input:`BidPx`MidPx);           
        syms:enlist ([]syms:`GOOG`TSLA)
  );
    
    / Request 2: 60-second snaps for 30 minutes window (GOOG, META)
    req2:([] 
        Id:1?0Ng;
        SnapFreq:enlist 60;           
        StartTimeUtc:enlist startTime;           
        EndTimeUtc:enlist startTime + 0D00:30:00;           
        StatsOverSnaps:enlist ([]Operator:`FIRST`LAST`MAX; Input:`AskPx`BidPx`TradeQty);           
        syms:enlist ([]syms:`GOOG`META)
	);
    
    / Add requests to CEP
    .cep.addStatsReq[req1];
    .cep.addStatsReq[req2];
    
    -1 "\nPending requests:";
    show .cep._PendingStatsReq;
    
    -1 "\n2. Waiting for tickerplant data...";
    -1 "Tickerplant is generating and publishing data automatically";
    -1 "Stats will appear as requests complete";
    -1 "\nMonitor progress:";
    -1 "  .cep.Stats - View completed statistics";
    -1 "  .cep._PendingStatsReq - View pending requests";
    -1 "  .cep.Snap_1 - View received 1-second snaps";

    / Show results
    -1 "\n3. Results:\n";
    -1 "Stats table:";
    show .cep.Stats;
    
    -1 "\nRemaining pending requests:";
    show .cep._PendingStatsReq;
    
    / Show sample of snap data
    -1 "\nSample snap data (first 5 rows each):";
    -1 "Snap_1 (1-second):";
    show 5#.cep.Snap_1;
    -1 "\nSnap_60 (1-minute):";  
    show 5#.cep.Snap_60;
 }

\d .

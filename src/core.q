/ Core CEP Functionality
/ CEP System - Core Module

\d .cep
/ ============================================================================
/ REQUEST MANAGEMENT
/ ============================================================================

/ Add statistics requests to pending queue
addStatsReq:{[req]
    / Validate input
    /.cep.validateStatsReq[req];
    
    / Add Id if not present
    if[not `Id in cols req; req:update Id:1?0Ng from req];
    
    / Insert into user and pending requests table
    `.cep.CepStatsReq upsert select Id, SnapFreq, StartTimeUtc, EndTimeUtc, StatsOverSnaps, syms from req;
    `.cep._PendingStatsReq upsert select Id, SnapFreq, StartTimeUtc, EndTimeUtc, StatsOverSnaps, syms from req;
    
    logMsg "Added ",string[count req]," request(s) to User and pending queue";
    logMsg "Pending requests: ",string count .cep._PendingStatsReq;
 };

/ Check if request is complete (all symbols have data at or beyond EndTimeUtc)
isRequestComplete:{[reqId; snapFreq;req]
    reqSyms:(first req`syms)`syms;

    / Get the appropriate snap table
    snapTable:get .cep.getSnapTable[snapFreq];

    / Check if all symbols have at least one snap at or beyond EndTimeUtc
    all {[snapTable; reqsym; endTime]
        0 < count select from snapTable where sym=reqsym, SnapTimeUtc >= endTime
    }[snapTable;;first req`EndTimeUtc] each reqSyms
 };

/ Complete a request by calculating stats and moving to output
completeRequest:{[reqId;snapFreq;req]
    
     -1"Geting into complete request....";
    / Get snap data for calculation
    calc:.cep.calculateStats[reqId;snapFreq;req];

    / Insert into Stats table
    statsRow:`Id`StartTimeUtc`EndTimeUtc`SnapFreq`Calc!(req`Id; req`StartTimeUtc; req`EndTimeUtc; req`SnapFreq; enlist calc);
    `.cep.Stats insert (value statsRow);

    / Remove from pending requests
    delete from `.cep._PendingStatsReq where Id=reqId;

    logMsg "Completed request: ",string reqId;
 };

/ ============================================================================
/ DATA FEED AND UPDATE HANDLER
/ ============================================================================

/ Main update function - called when new snap data arrives
upd:{[tableName; data]
    / Determine frequency from table name
    freq:$[tableName=`Snap_1; 1; tableName=`Snap_60; 60; tableName=`Snap_3600; 3600; 0];
    if[freq=0; logMsg "Unknown table: ",string tableName; :()];

    / Insert data into appropriate snap table
    snapTable:.cep.getSnapTable[freq];
    snapTable upsert data;

    / Get snap times for processing
    /snapTimes:exec distinct SnapTimeUtc from data;

    / Process pending requests that match this frequency
    relevantReqs:select from .cep._PendingStatsReq where SnapFreq=freq;
    reqIds:exec distinct Id from relevantReqs;
    / Check each relevant request for completion
    {[reqId; freq]
        req: select from .cep._PendingStatsReq where Id = reqId;
        / Check if any snap time affects this request window
            / Check if request is now complete
            if[.cep.isRequestComplete[reqId;freq;req];
                 -1"Request Completed...";
                .cep.completeRequest[reqId;freq;req];
               ];
    }[;freq] each reqIds;
 };

/ ============================================================================
/ TICKERPLANT CONNECTION
/ ============================================================================

/ Tickerplant connection configuration

.cep.config.tickerplant.host:`localhost;
.cep.config.tickerplant.port:5010;
.cep.config.tickerplant.autoConnect:1b;
.cep.config.tickerplant.subscribeTables:`Snap_1`Snap_60`Snap_3600;

/ Connect to tickerplant and subscribe to tables
connectToTP:{[]
    tpHost:.cep.config.tickerplant.host;
    tpPort:.cep.config.tickerplant.port;
    
    logMsg "Attempting to connect to tickerplant at ",string[tpHost],":",string tpPort;
    
    / Try to connect
    .cep.tpHandle:@[hopen;`$":",(string tpHost),":",string tpPort;{logMsg "Connection failed: ",x; 0Ni}];
    
    if[null .cep.tpHandle;
        logMsg "Failed to connect to tickerplant";
        :0b
    ];
    
    tpHandle:.cep.tpHandle;
    logMsg "Connected to tickerplant on handle ",string tpHandle;
    
    / Subscribe to tables
    tbls:.cep.config.tickerplant.subscribeTables;
    logMsg "Subscribing to tables: ",.Q.s1 tbls;
    
    / Subscribe to each table
    {[h;tbl]
        logMsg "Subscribing to ",string tbl;
        / Standard tickerplant subscription: .tp.sub[table;syms;handle]
        @[(neg h);(".tp.sub";tbl;`);{logMsg "Subscription error: ",x}];
    }[tpHandle] each tbls;
    
    logMsg "Connection and subscription complete";
    :1b
 };

/ Initialize tickerplant connection
initTPConnection:{[]
    if[not .cep.config.tickerplant.autoConnect;
        logMsg "Tickerplant auto-connect disabled";
        :0b
    ];
    
    logMsg "Initializing tickerplant connection...";
    
    / Connect and subscribe
    .cep.connectToTP[]
 };


/ ============================================================================
/ INITIALIZATION
/ ============================================================================

init:{[]
    logMsg "CEP System initialized";
    -1 "Available functions:";
    -1 "  .cep.addStatsReq[req] - Add statistics requests";  
    -1 "  .cep.Stats - View completed statistics";
    -1 "  .cep._PendingStatsReq - View pending requests";
    -1 "  .cep.runDemo[] - Run demonstration";
    -1 "  .cep.connectToTP[] - Connect and subscribe to tickerplant";
    
    / Try to connect to tickerplant if configured
    initTPConnection[]
 };

\d .



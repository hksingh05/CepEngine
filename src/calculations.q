/ Calculation Engine
/ CEP System - Calculations Module
\d .cep
/ ============================================================================
/ CALCULATION ENGINE
/ ============================================================================

/ Apply operator to data
applyOperator:{[op; data]
    if[0=count data; :0n];
    $[op=`FIRST; first data;
      op=`LAST; last data;
      op=`MIN; min data;
      op=`MAX; max data;
      op=`AVG; avg data;
      '"Unknown operator: ",string op]
 }

/ Calculate statistics for a request and symbol set
calculateStats:{[reqId; snapFreq;req]

    / Get symbols for this request
    reqSyms:(first req`syms)`syms;
	
	snapData:get .cep.getSnapTable[snapFreq];
	if[0=count snapData; :()];

    / Filter snap data for requested symbols and time window
    relevantSnaps:select from snapData where sym in reqSyms, SnapTimeUtc within (first req`StartTimeUtc; first req`EndTimeUtc);
	if[0=count relevantSnaps; :()];

    / Add MidPx column for calculations
    relevantSnaps:update MidPx:.cep.calcMidPx[BidPx; AskPx] from relevantSnaps;

    statsSpecs:first req`StatsOverSnaps;
	ops:exec Operator from statsSpecs;
	inputs:exec Input from statsSpecs;
	//results:();
	
    / Process each statistic request
    results:(uj/){[data;ops;inputs;reqsym]
        symData:select from data where sym=reqsym;
        if[0=count symData; :(::)];
        
        // Build row with Syms column
        row:enlist[`Syms]!enlist reqsym;
        
        // Calculate each operator-input pair and add to row
        row:row,(genColName'[ops;inputs])!{[symData;op;input] 
            .cep.applyOperator[op;symData[input]]
        }[symData]'[ops;inputs];
        
       (),enlist row
    }[relevantSnaps;ops;inputs;] each reqSyms;
	
	results
 }

\d .

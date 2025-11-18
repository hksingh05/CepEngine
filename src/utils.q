/ Utility Functions
/ CEP System - Utils Module

\d .cep
/ ============================================================================
/ UTILITY FUNCTIONS
/ ============================================================================

/ Calculate midpoint price
calcMidPx:{[bidPx; askPx] (bidPx + askPx) % 2f};

/ Get snap table by frequency
getSnapTable:{[freq]
    ` sv `.cep,(`$"Snap_",string freq)
 };

genColName:{[op;input] `$string[op],"_",string[input]};

/ Validate CepStatsReq input
validateStatsReq:{[req]
    / Check required columns
    reqCols:`SnapFreq`StartTimeUtc`EndTimeUtc`StatsOverSnaps`syms;
    if[not all reqCols in cols req; 
        '"Missing required columns in CepStatsReq. Required: ",", " sv string reqCols];
    
    / Validate SnapFreq values
    if[not all (exec distinct SnapFreq from req) in 1 60 3600; 
        '"Invalid SnapFreq - must be 1, 60, or 3600"];
    
    / Validate operators and inputs in StatsOverSnaps
    {[statsRow]
        if[not all statsRow`Operator in LEGAL_OPERATORS; 
            '"Invalid operator in StatsOverSnaps. Legal: ",", " sv string LEGAL_OPERATORS];
        if[not all statsRow.Input in LEGAL_INPUTS; 
            '"Invalid input column in StatsOverSnaps. Legal: ",", " sv string LEGAL_INPUTS];
    } each req`StatsOverSnaps;
    
    1b / Valid
 };

/ Log message with timestamp
logMsg:{[msg]
    -1 string[.z.p]," | ",msg;
 };

\d .

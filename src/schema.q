/ CEP System - Schema Module

\d .cep 

/ ============================================================================
/ TABLE SCHEMAS
/ ============================================================================

/ Initialize snap tables with correct schema
Snap_1:([]sym:`$(); SnapTimeUtc:`timestamp$(); BidPx:`float$(); BidQty:`long$(); AskPx:`float$(); AskQty:`long$(); TradePx:`float$(); TradeQty:`long$());
Snap_60:([]sym:`$(); SnapTimeUtc:`timestamp$(); BidPx:`float$(); BidQty:`long$(); AskPx:`float$(); AskQty:`long$(); TradePx:`float$(); TradeQty:`long$());
Snap_3600:([]sym:`$(); SnapTimeUtc:`timestamp$(); BidPx:`float$(); BidQty:`long$(); AskPx:`float$(); AskQty:`long$(); TradePx:`float$(); TradeQty:`long$());

/ User requests table
CepStatsReq:([]Id:`guid$(); SnapFreq:`long$(); StartTimeUtc:`timestamp$(); EndTimeUtc:`timestamp$(); StatsOverSnaps:(); syms:());

/ Pending requests table 
.cep._PendingStatsReq:([]Id:`guid$(); SnapFreq:`long$(); StartTimeUtc:`timestamp$(); EndTimeUtc:`timestamp$(); StatsOverSnaps:(); syms:());

/ Final stats output table
Stats:([]Id:`guid$(); StartTimeUtc:`timestamp$(); EndTimeUtc:`timestamp$(); SnapFreq:`long$(); Calc:());

/ ============================================================================
/ CONSTANTS
/ ============================================================================

/ Legal operators and inputs for validation
LEGAL_OPERATORS:`FIRST`LAST`MIN`MAX`AVG;
LEGAL_INPUTS:`BidPx`BidQty`AskPx`AskQty`TradePx`TradeQty`MidPx;

\d .


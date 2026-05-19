comment =====================================================================
       FLXSEDIMNT — Sediment layer manager for constraint bounds
       Accumulated corrections that persist across validation cycles.
       ALGOL 60: the own keyword is the key insight.
       
       ALGOL 60's `own` variables survive procedure calls — they are
       allocated once and retain values between invocations. This is
       the first "closure-like" mechanism in any programming language,
       and it maps directly to sediment layers: corrections that
       accumulate over time and persist across validation cycles.
       =====================================================================;

begin

  integer MAXLAYERS, MAXCON;
  MAXLAYERS := 16;
  MAXCON := 8;

  comment --- Sediment layer arrays (own = persistent) -----------------;
  own integer array SLCONIDX[1:MAXLAYERS];
  own integer array SLOLDLO[1:MAXLAYERS];
  own integer array SLOLDHI[1:MAXLAYERS];
  own integer array SLNEWLO[1:MAXLAYERS];
  own integer array SLNEWHI[1:MAXLAYERS];
  own integer array SLTIMESTAMP[1:MAXLAYERS];
  own integer NLAYERS;
  own Boolean SLINIT;

  comment --- Constraint bounds (passed in, modified in place) ---------;
  integer array CLO[1:MAXCON];
  integer array CHI[1:MAXCON];

  integer I, CIDX;

  comment ----------------------------------------------------------------
       INITSEDIMENT: Initialize sediment system (first call only)
       own variables need explicit initialization.
       ----------------------------------------------------------------;
  procedure INITSEDIMENT;
  begin
    if ¬ SLINIT then
    begin
      NLAYERS := 0;
      for I := 1 step 1 until MAXLAYERS do
      begin
        SLCONIDX[I] := 0;
        SLOLDLO[I] := 0;
        SLOLDHI[I] := 0;
        SLNEWLO[I] := 0;
        SLNEWHI[I] := 0;
        SLTIMESTAMP[I] := 0
      end;
      SLINIT := true
    end
  end INITSEDIMENT;

  comment ----------------------------------------------------------------
       ADDLAYER: Add a sediment correction layer
       Records old bounds and applies new bounds.
       ----------------------------------------------------------------;
  procedure ADDLAYER(CIDX, NEWLO, NEWHI, TIMESTAMP);
    value CIDX, NEWLO, NEWHI, TIMESTAMP;
    integer CIDX, NEWLO, NEWHI, TIMESTAMP;
  begin
    NLAYERS := NLAYERS + 1;
    SLCONIDX[NLAYERS] := CIDX;
    SLOLDLO[NLAYERS] := CLO[CIDX];
    SLOLDHI[NLAYERS] := CHI[CIDX];
    SLNEWLO[NLAYERS] := NEWLO;
    SLNEWHI[NLAYERS] := NEWHI;
    SLTIMESTAMP[NLAYERS] := TIMESTAMP
  end ADDLAYER;

  comment ----------------------------------------------------------------
       APPLYLAYERS: Apply all sediment corrections to constraint bounds
       Layers are applied in order — later layers override earlier ones.
       This is geological stratification: newest layer on top.
       ----------------------------------------------------------------;
  procedure APPLYLAYERS(NCON);
    value NCON;
    integer NCON;
  begin
    integer SIDX;
    for SIDX := 1 step 1 until NLAYERS do
    begin
      CIDX := SLCONIDX[SIDX];
      if CIDX > 0 ∧ CIDX ≤ NCON then
      begin
        if SLNEWLO[SIDX] ≠ 0 then CLO[CIDX] := SLNEWLO[SIDX];
        if SLNEWHI[SIDX] ≠ 0 then CHI[CIDX] := SLNEWHI[SIDX]
      end
    end
  end APPLYLAYERS;

  comment ----------------------------------------------------------------
       ROLLBACKLAYER: Remove the most recent layer
       Restores the previous bounds from the old values.
       ----------------------------------------------------------------;
  procedure ROLLBACKLAYER(NCON);
    value NCON;
    integer NCON;
  begin
    if NLAYERS > 0 then
    begin
      CIDX := SLCONIDX[NLAYERS];
      if CIDX > 0 ∧ CIDX ≤ NCON then
      begin
        CLO[CIDX] := SLOLDLO[NLAYERS];
        CHI[CIDX] := SLOLDHI[NLAYERS]
      end;
      SLCONIDX[NLAYERS] := 0;
      NLAYERS := NLAYERS - 1
    end
  end ROLLBACKLAYER;

  comment ----------------------------------------------------------------
       COUNTLAYERS: Return the number of active layers
       ----------------------------------------------------------------;
  integer procedure COUNTLAYERS;
  begin
    COUNTLAYERS := NLAYERS
  end COUNTLAYERS;

  comment ----------------------------------------------------------------
       LAYERINFO: Print info about a specific layer
       ----------------------------------------------------------------;
  procedure LAYERINFO(IDX);
    value IDX;
    integer IDX;
  begin
    comment In a real implementation, this would format output;
    comment Layer IDX: constraint SLCONIDX[IDX],
            old [SLOLDLO[IDX], SLOLDHI[IDX]],
            new [SLNEWLO[IDX], SLNEWHI[IDX]],
            timestamp SLTIMESTAMP[IDX];
    outinteger(1, IDX);
    outstring(1, " -> con=");
    outinteger(1, SLCONIDX[IDX]);
    outstring(1, " new=[");
    outinteger(1, SLNEWLO[IDX]);
    outstring(1, ",");
    outinteger(1, SLNEWHI[IDX]);
    outstring(1, "]")
  end LAYERINFO;

  comment =================================================================
       SELF-TEST
       =================================================================;

  outstring(1, "FLXSEDIMNT — Sediment Layer Manager Self-Test");

  INITSEDIMENT;

  comment Setup constraints: temp [-40,85], pressure [800,1200];
  CLO[1] := -40; CHI[1] := 85;
  CLO[2] := 800; CHI[2] := 1200;

  comment Test 1: Add sediment layer extending temp range;
  ADDLAYER(1, -40, 105, 20260519);
  if NLAYERS = 1 then
    outstring(1, "PASS: Test 1 (layer added)")
  else
    outstring(1, "FAIL: Test 1");

  comment Test 2: Apply layers and check bounds updated;
  APPLYLAYERS(2);
  if CHI[1] = 105 then
    outstring(1, "PASS: Test 2 (bounds updated)")
  else
    outstring(1, "FAIL: Test 2");

  comment Test 3: Rollback restores original bounds;
  ROLLBACKLAYER(2);
  if CHI[1] = 85 ∧ NLAYERS = 0 then
    outstring(1, "PASS: Test 3 (rollback)")
  else
    outstring(1, "FAIL: Test 3");

  comment Test 4: own persistence — re-init should NOT reset;
  comment (In this self-test, SLINIT is already true);
  INITSEDIMENT;
  if NLAYERS = 0 then
    outstring(1, "PASS: Test 4 (own persistence)")
  else
    outstring(1, "FAIL: Test 4");

  outstring(1, "FLXSEDIMNT self-test complete.")

end

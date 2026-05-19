comment =====================================================================
       FLXMAIN — Main program: wires together FLXCHECK, FLXFRACT,
       and FLXSEDIMNT for a complete constraint validation pipeline.
       ALGOL 60 implementation.
       =====================================================================;

begin

  integer MAXCON;
  MAXCON := 8;

  comment --- Shared state ---------------------------------------------;
  integer array CLO[1:MAXCON];
  integer array CHI[1:MAXCON];
  integer array CSEV[1:MAXCON];
  integer array SENSOR[1:MAXCON];
  integer NCONSTRAINTS;
  integer ERRORMASK, VIOLATED, TOTALSEVERITY;
  Boolean PASSED;

  comment --- Constants ------------------------------------------------;
  integer INT8MIN, INT8MAX;
  INT8MIN := -127;
  INT8MAX := 127;

  comment --- Work variables -------------------------------------------;
  integer I, J, BITVAL, TESTBIT;

  comment ================================================================
       CONSTRAINT ENGINE (inline — ALGOL 60 has no separate compilation)
       ================================================================;

  procedure SATURATE;
  begin
    for I := 1 step 1 until NCONSTRAINTS do
    begin
      if SENSOR[I] < INT8MIN then SENSOR[I] := INT8MIN;
      if SENSOR[I] > INT8MAX then SENSOR[I] := INT8MAX
    end
  end SATURATE;

  procedure ADDCONSTRAINT(LO, HI, SEV);
    value LO, HI, SEV;
    integer LO, HI, SEV;
  begin
    NCONSTRAINTS := NCONSTRAINTS + 1;
    CLO[NCONSTRAINTS] := LO;
    CHI[NCONSTRAINTS] := HI;
    CSEV[NCONSTRAINTS] := SEV
  end ADDCONSTRAINT;

  procedure CHECKCONSTRAINTS;
  begin
    ERRORMASK := 0;
    VIOLATED := 0;
    PASSED := true;
    for I := 1 step 1 until NCONSTRAINTS do
    begin
      if SENSOR[I] < CLO[I] ∨ SENSOR[I] > CHI[I] then
      begin
        VIOLATED := VIOLATED + 1;
        BITVAL := 1;
        for J := 1 step 1 until I - 1 do BITVAL := BITVAL × 2;
        ERRORMASK := ERRORMASK + BITVAL;
        PASSED := false
      end
    end
  end CHECKCONSTRAINTS;

  procedure COMPUTESEVERITY;
  begin
    integer SEVSUM;
    SEVSUM := 0;
    for I := 1 step 1 until NCONSTRAINTS do
    begin
      BITVAL := 1;
      for J := 1 step 1 until I - 1 do BITVAL := BITVAL × 2;
      TESTBIT := ERRORMASK - (ERRORMASK ÷ (BITVAL × 2)) × (BITVAL × 2);
      if TESTBIT ≥ BITVAL then SEVSUM := SEVSUM + CSEV[I]
    end;
    TOTALSEVERITY := SEVSUM
  end COMPUTESEVERITY;

  comment ================================================================
       FRACTURE ENGINE (inline)
       ================================================================;

  integer MAXC, MAXD;
  MAXC := 256;
  MAXD := 256;

  integer array ADJ[1:8, 1:8];
  integer array BCOUNT[1:8];
  integer BCONSTRAINTS[1:8, 1:8];
  integer NBLOCKS;

  procedure BUILDDEP;
  begin
    for I := 1 step 1 until NCONSTRAINTS do
      for J := 1 step 1 until NCONSTRAINTS do
        if I = J then ADJ[I, J] := 1 else ADJ[I, J] := 0
  end BUILDDEP;

  comment ================================================================
       SEDIMENT MANAGER (inline, with own)
       ================================================================;

  own integer array SLNEWLO[1:16];
  own integer array SLNEWHI[1:16];
  own integer array SLCONIDX[1:16];
  own integer NLAYERS;
  own Boolean SLINIT;

  procedure INITSEDIMENT;
  begin
    if ¬ SLINIT then
    begin
      NLAYERS := 0;
      SLINIT := true
    end
  end INITSEDIMENT;

  procedure ADDSEDIMENT(CIDX, NEWLO, NEWHI);
    value CIDX, NEWLO, NEWHI;
    integer CIDX, NEWLO, NEWHI;
  begin
    NLAYERS := NLAYERS + 1;
    SLCONIDX[NLAYERS] := CIDX;
    SLNEWLO[NLAYERS] := NEWLO;
    SLNEWHI[NLAYERS] := NEWHI
  end ADDSEDIMENT;

  procedure APPLYSEDIMENT;
  begin
    integer SIDX, CIDX;
    for SIDX := 1 step 1 until NLAYERS do
    begin
      CIDX := SLCONIDX[SIDX];
      if CIDX > 0 ∧ CIDX ≤ NCONSTRAINTS then
      begin
        if SLNEWLO[SIDX] ≠ 0 then CLO[CIDX] := SLNEWLO[SIDX];
        if SLNEWHI[SIDX] ≠ 0 then CHI[CIDX] := SLNEWHI[SIDX]
      end
    end
  end APPLYSEDIMENT;

  comment ================================================================
       FULL PIPELINE
       ================================================================;

  procedure VALIDATEALL;
  begin
    SATURATE;
    APPLYSEDIMENT;
    CHECKCONSTRAINTS;
    COMPUTESEVERITY
  end VALIDATEALL;

  comment ================================================================
       MAIN
       ================================================================;

  outstring(1, "FLXMAIN — Flux Constraint Pipeline");
  outstring(1, "===================================");

  INITSEDIMENT;

  comment Register constraints;
  ADDCONSTRAINT(-40, 85, 1);
  ADDCONSTRAINT(800, 1200, 2);
  ADDCONSTRAINT(0, 50, 1);
  ADDCONSTRAINT(-10, 10, 3);

  outstring(1, "Constraints: 4 registered");

  comment Build dependency graph;
  BUILDDEP;
  outstring(1, "Dependency graph: diagonal (independent)");

  comment Scenario 1: All in bounds;
  SENSOR[1] := 25; SENSOR[2] := 900; SENSOR[3] := 12; SENSOR[4] := 0;
  VALIDATEALL;
  if PASSED then
    outstring(1, "Scenario 1: ALL PASS")
  else
    outstring(1, "Scenario 1: FAIL");

  comment Scenario 2: Multiple violations;
  SENSOR[1] := 100; SENSOR[2] := 500; SENSOR[3] := 60; SENSOR[4] := 20;
  VALIDATEALL;
  outstring(1, "Scenario 2: Errors detected");
  outinteger(1, ERRORMASK);
  outinteger(1, TOTALSEVERITY);

  comment Scenario 3: Sediment extends bounds;
  ADDSEDIMENT(1, -40, 105);
  SENSOR[1] := 95; SENSOR[2] := 900; SENSOR[3] := 12; SENSOR[4] := 0;
  VALIDATEALL;
  if PASSED then
    outstring(1, "Scenario 3: Sediment correction applied — PASS")
  else
    outstring(1, "Scenario 3: FAIL");

  outstring(1, "FLXMAIN complete.")

end

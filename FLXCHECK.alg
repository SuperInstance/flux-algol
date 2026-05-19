comment =====================================================================
       FLXCHECK — THE CORE: Exact INT8 bounds checking with sediment
       Constraint engine in ALGOL 60.
       Parallel arrays instead of structs. own for sediment persistence.
       =====================================================================;

begin

  comment --- Constants -------------------------------------------------;
  integer INT8MIN, INT8MAX, MAXCONSTRAINTS, MAXSEDIMENT;
  INT8MIN := -127;
  INT8MAX := 127;
  MAXCONSTRAINTS := 8;
  MAXSEDIMENT := 16;

  comment --- Constraint arrays (parallel — no structs in ALGOL 60) ----;
  integer array CLO[1:MAXCONSTRAINTS];
  integer array CHI[1:MAXCONSTRAINTS];
  integer array CSEV[1:MAXCONSTRAINTS];
  integer NCONSTRAINTS;

  comment --- Sensor values --------------------------------------------;
  integer array SENSOR[1:MAXCONSTRAINTS];

  comment --- Result ----------------------------------------------------;
  integer ERRORMASK;
  integer VIOLATED;
  integer TOTALSEVERITY;
  Boolean PASSED;

  comment --- Sediment arrays (parallel) --------------------------------;
  own integer array SCONIDX[1:MAXSEDIMENT];
  own integer array SOLDLO[1:MAXSEDIMENT];
  own integer array SOLDHI[1:MAXSEDIMENT];
  own integer array SNEWLO[1:MAXSEDIMENT];
  own integer array SNEWHI[1:MAXSEDIMENT];
  own integer NSEDIMENT;
  own Boolean SEDIMENTINIT;

  comment --- Work variables -------------------------------------------;
  integer I, J, BITVAL, WORKVAL;

  comment ----------------------------------------------------------------
       SATURATE: Clamp sensor values to INT8 range
       ----------------------------------------------------------------;
  procedure SATURATE;
  begin
    for I := 1 step 1 until NCONSTRAINTS do
    begin
      if SENSOR[I] < INT8MIN then SENSOR[I] := INT8MIN;
      if SENSOR[I] > INT8MAX then SENSOR[I] := INT8MAX
    end
  end SATURATE;

  comment ----------------------------------------------------------------
       APPLYSEDIMENT: Layer corrections onto constraint bounds
       The own keyword makes sediment persist across calls.
       This is the first closure-like mechanism in any language.
       ----------------------------------------------------------------;
  procedure APPLYSEDIMENT;
  begin
    integer SIDX, CIDX;
    for SIDX := 1 step 1 until NSEDIMENT do
    begin
      CIDX := SCONIDX[SIDX];
      if CIDX > 0 ∧ CIDX ≤ NCONSTRAINTS then
      begin
        comment Apply new bounds if specified (0 = no change);
        if SNEWLO[SIDX] ≠ 0 then CLO[CIDX] := SNEWLO[SIDX];
        if SNEWHI[SIDX] ≠ 0 then CHI[CIDX] := SNEWHI[SIDX]
      end
    end
  end APPLYSEDIMENT;

  comment ----------------------------------------------------------------
       CHECKCONSTRAINTS: Compare each sensor to its bounds
       Error mask is a bitmask: bit i-1 set if constraint i violated.
       ----------------------------------------------------------------;
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
        comment Compute 2^(I-1) by shifting;
        BITVAL := 1;
        for J := 1 step 1 until I - 1 do BITVAL := BITVAL × 2;
        ERRORMASK := ERRORMASK + BITVAL;
        PASSED := false
      end
    end
  end CHECKCONSTRAINTS;

  comment ----------------------------------------------------------------
       COMPUTESEVERITY: Sum severities of violated constraints
       ----------------------------------------------------------------;
  procedure COMPUTESEVERITY;
  begin
    integer SEVSUM, TESTBIT;
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

  comment ----------------------------------------------------------------
       VALIDATEALL: Full pipeline — saturate, sediment, check, severity
       ----------------------------------------------------------------;
  procedure VALIDATEALL;
  begin
    SATURATE;
    APPLYSEDIMENT;
    CHECKCONSTRAINTS;
    COMPUTESEVERITY
  end VALIDATEALL;

  comment ----------------------------------------------------------------
       ADDCONSTRAINT: Register a constraint
       ----------------------------------------------------------------;
  procedure ADDCONSTRAINT(LO, HI, SEVERITY);
    value LO, HI, SEVERITY;
    integer LO, HI, SEVERITY;
  begin
    NCONSTRAINTS := NCONSTRAINTS + 1;
    CLO[NCONSTRAINTS] := LO;
    CHI[NCONSTRAINTS] := HI;
    CSEV[NCONSTRAINTS] := SEVERITY
  end ADDCONSTRAINT;

  comment ----------------------------------------------------------------
       ADDSEDIMENT: Add a sediment correction layer
       ----------------------------------------------------------------;
  procedure ADDSEDIMENT(CIDX, NEWLO, NEWHI);
    value CIDX, NEWLO, NEWHI;
    integer CIDX, NEWLO, NEWHI;
  begin
    NSEDIMENT := NSEDIMENT + 1;
    SCONIDX[NSEDIMENT] := CIDX;
    SOLDLO[NSEDIMENT] := CLO[CIDX];
    SOLDHI[NSEDIMENT] := CHI[CIDX];
    SNEWLO[NSEDIMENT] := NEWLO;
    SNEWHI[NSEDIMENT] := NEWHI
  end ADDSEDIMENT;

  comment ----------------------------------------------------------------
       INIT: Reset state for self-test
       ----------------------------------------------------------------;
  procedure INIT;
  begin
    NCONSTRAINTS := 0;
    ERRORMASK := 0;
    VIOLATED := 0;
    TOTALSEVERITY := 0;
    PASSED := true;
    if ¬ SEDIMENTINIT then
    begin
      NSEDIMENT := 0;
      SEDIMENTINIT := true
    end
  end INIT;

  comment =================================================================
       SELF-TEST
       =================================================================;

  INIT;

  comment Test 1: All values in bounds;
  ADDCONSTRAINT(-40, 85, 1);
  ADDCONSTRAINT(800, 1200, 2);
  ADDCONSTRAINT(0, 50, 1);

  SENSOR[1] := 25;
  SENSOR[2] := 900;
  SENSOR[3] := 12;
  VALIDATEALL;

  if PASSED then
    outstring(1, "PASS: Test 1 (all in bounds)")
  else
    outstring(1, "FAIL: Test 1");

  comment Test 2: Temperature violation;
  INIT;
  ADDCONSTRAINT(-40, 85, 1);
  ADDCONSTRAINT(800, 1200, 2);
  ADDCONSTRAINT(0, 50, 1);

  SENSOR[1] := 100;
  SENSOR[2] := 900;
  SENSOR[3] := 12;
  VALIDATEALL;

  if ¬ PASSED then
    outstring(1, "PASS: Test 2 (temp caught)")
  else
    outstring(1, "FAIL: Test 2 (violation missed)");

  comment Test 3: Boundary — exactly at LO;
  INIT;
  ADDCONSTRAINT(-40, 85, 1);
  SENSOR[1] := -40;
  VALIDATEALL;

  if PASSED then
    outstring(1, "PASS: Test 3 (boundary LO)")
  else
    outstring(1, "FAIL: Test 3 (boundary)");

  comment Test 4: INT8 saturation;
  SENSOR[1] := -200;
  SATURATE;
  if SENSOR[1] = INT8MIN then
    outstring(1, "PASS: Test 4 (INT8 saturate)")
  else
    outstring(1, "FAIL: Test 4 (saturate)");

  comment Test 5: Sediment correction extends bounds;
  INIT;
  ADDCONSTRAINT(-40, 85, 1);
  ADDCONSTRAINT(800, 1200, 2);
  ADDCONSTRAINT(0, 50, 1);

  ADDSEDIMENT(1, -40, 105);
  SENSOR[1] := 95;
  SENSOR[2] := 900;
  SENSOR[3] := 12;
  VALIDATEALL;

  if PASSED then
    outstring(1, "PASS: Test 5 (sediment extended bounds)")
  else
    outstring(1, "FAIL: Test 5 (sediment)");

  outstring(1, "FLXCHECK self-test complete.")

end

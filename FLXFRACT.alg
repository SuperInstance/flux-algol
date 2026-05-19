comment =====================================================================
       FLXFRACT — Fracture engine: decompose constraint systems into
       independent blocks via bipartite graph BFS.
       ALGOL 60 implementation using parallel arrays.
       =====================================================================;

begin

  integer MAXC, MAXD, MAXBLK;
  MAXC := 256;
  MAXD := 256;
  MAXBLK := 256;

  comment --- Adjacency matrix: constraint i depends on dimension j ----;
  integer array ADJ[1:MAXC, 1:MAXD];

  comment --- Block storage (parallel arrays) --------------------------;
  integer array BCOUNT[1:MAXBLK];
  integer array BDCOUNT[1:MAXBLK];
  integer array BCONSTRAINTS[1:MAXBLK, 1:MAXC];
  integer array BDIMS[1:MAXBLK, 1:MAXD];
  integer N BLOCKS;
  integer LARGESTBLK;

  comment --- BFS work arrays ------------------------------------------;
  integer array QUEUE[1:512];
  integer array VISCON[1:MAXC];
  integer array VISTIM[1:MAXD];
  integer QHEAD, QTAIL, CURRENT;

  integer I, J, K, NBC, NBD, BSIZE;

  comment ----------------------------------------------------------------
       BUILDDEPGRAPH: Construct bipartite dependency adjacency
       constraint i checks dimension j → ADJ(i,j) = 1
       For diagonal structure: constraint i checks dim i.
       ----------------------------------------------------------------;
  procedure BUILDDEPGRAPH(NC, ND);
    value NC, ND;
    integer NC, ND;
  begin
    for I := 1 step 1 until NC do
      for J := 1 step 1 until ND do
        ADJ[I, J] := 0;
    comment Diagonal: each constraint i depends on dimension i;
    for I := 1 step 1 until NC do
      if I ≤ ND then ADJ[I, I] := 1
  end BUILDDEPGRAPH;

  comment ----------------------------------------------------------------
       FINDBLOCKS: BFS from each unvisited constraint to find connected
       components in the bipartite dependency graph.
       Positive queue entries = constraints, negative = dimensions.
       ----------------------------------------------------------------;
  procedure FINDBLOCKS(NC, ND);
    value NC, ND;
    integer NC, ND;
  begin
    NBLOCKS := 0;
    LARGESTBLK := 0;

    for I := 1 step 1 until NC do VISCON[I] := 0;
    for I := 1 step 1 until ND do VISTIM[I] := 0;

    for I := 1 step 1 until NC do
    begin
      if VISCON[I] = 1 then goto ENDBLOCK;

      comment BFS from constraint I;
      NBC := 0;
      NBD := 0;
      QHEAD := 1;
      QTAIL := 1;
      QUEUE[QTAIL] := I;
      QTAIL := QTAIL + 1;
      VISCON[I] := 1;

      for J := 1 step 1 until MAXC do
        BCONSTRAINTS[NBLOCKS + 1, J] := 0;
      for J := 1 step 1 until MAXD do
        BDIMS[NBLOCKS + 1, J] := 0;

      while QHEAD < QTAIL do
      begin
        CURRENT := QUEUE[QHEAD];
        QHEAD := QHEAD + 1;

        if CURRENT > 0 then
        begin
          comment Constraint node;
          NBC := NBC + 1;
          BCONSTRAINTS[NBLOCKS + 1, NBC] := CURRENT;
          for J := 1 step 1 until ND do
            if ADJ[CURRENT, J] = 1 ∧ VISTIM[J] = 0 then
            begin
              VISTIM[J] := 1;
              QUEUE[QTAIL] := -J;
              QTAIL := QTAIL + 1
            end
        end
        else
        begin
          comment Dimension node (stored as negative);
          J := -CURRENT;
          NBD := NBD + 1;
          BDIMS[NBLOCKS + 1, NBD] := J;
          for K := 1 step 1 until NC do
            if ADJ[K, J] = 1 ∧ VISCON[K] = 0 then
            begin
              VISCON[K] := 1;
              QUEUE[QTAIL] := K;
              QTAIL := QTAIL + 1
            end
        end
      end;

      NBLOCKS := NBLOCKS + 1;
      BCOUNT[NBLOCKS] := NBC;
      BDCOUNT[NBLOCKS] := NBD;
      if NBC > LARGESTBLK then LARGESTBLK := NBC;

ENDBLOCK:
    end
  end FINDBLOCKS;

  comment ----------------------------------------------------------------
       COALESCEMASKS: Bitwise OR of block masks into global mask
       Zero false negatives guaranteed by Boolean algebra.
       ----------------------------------------------------------------;
  procedure COALESCEMASKS(BLOCKMASKS, GLOBALMASK, NBLK, NBITS);
    value NBLK, NBITS;
    integer array BLOCKMASKS, GLOBALMASK;
    integer NBLK, NBITS;
  begin
    integer B, II;
    for II := 1 step 1 until NBITS do GLOBALMASK[II] := 0;
    for B := 1 step 1 until NBLK do
      for II := 1 step 1 until NBITS do
        if BLOCKMASKS[B, II] = 1 ∨ GLOBALMASK[II] = 1 then
          GLOBALMASK[II] := 1
        else
          GLOBALMASK[II] := 0
  end COALESCEMASKS;

  comment ----------------------------------------------------------------
       VERIFYCOALESCE: Check that coalesced ≥ monolithic (no false neg)
       ----------------------------------------------------------------;
  Boolean procedure VERIFYCOALESCE(COALESCED, MONOLITHIC, NBITS);
    value NBITS;
    integer array COALESCED, MONOLITHIC;
    integer NBITS;
  begin
    Boolean OK;
    OK := true;
    for I := 1 step 1 until NBITS do
      if MONOLITHIC[I] = 1 ∧ COALESCED[I] = 0 then
      begin
        OK := false;
        goto VERIFIEDONE
      end;
VERIFIEDONE:
    VERIFYCOALESCE := OK
  end VERIFYCOALESCE;

  comment =================================================================
       SELF-TEST
       =================================================================;

  outstring(1, "FLXFRACT — Fracture Engine Self-Test");

  comment Build a 6-constraint, 4-dimension system;
  BUILDDEPGRAPH(6, 4);

  comment Override: constraints 1,2 share dim 1; constraints 3,4 share dim 2;
  ADJ[1, 1] := 1; ADJ[2, 1] := 1;
  ADJ[3, 2] := 1; ADJ[4, 2] := 1;
  ADJ[5, 3] := 1; ADJ[6, 4] := 1;

  FINDBLOCKS(6, 4);

  comment Expect: block A = {1,2} on dim 1, block B = {3,4} on dim 2,
           block C = {5} on dim 3, block D = {6} on dim 4;
  if NBLOCKS = 4 then
    outstring(1, "PASS: 4 blocks found")
  else
    outstring(1, "FAIL: expected 4 blocks");

  outstring(1, "FLXFRACT self-test complete.")

end

# Flux ALGOL — What Parallel Arrays and `own` Teach About Sediment and Storage

ALGOL 60 (1960) is the mother of structured programming. It introduced `begin`/`end` blocks, lexical scoping, and recursive procedures. It runs in academic contexts and historical implementations. This repo implements the Flux constraint engine in ALGOL 60.

## How to Read ALGOL 60

ALGOL 60 looks unfamiliar but is surprisingly regular. It's the ancestor of Pascal, C, and every block-structured language.

```algol
comment This is a comment, ending with a semicolon;

begin
  integer X;                    comment declare integer;
  real Y;                       comment declare real;
  Boolean FLAG;                 comment declare Boolean;
  integer array A[1:10];        comment array, 1-indexed;
  own integer COUNT;            comment PERSISTENT across calls — the key insight;

  X := 42;                      comment assignment (:= not =);
  FLAG := true;                 comment Boolean literal;

  for I := 1 step 1 until 10 do  comment counted loop;
  begin
    ...
  end;

  if X > 0 then                   comment conditional;
    outinteger(1, X)
  else
    outinteger(1, -X);

  procedure SQUARE(N);            comment procedure declaration;
    value N;                      comment pass by value;
    integer N;                    comment type specification;
  begin
    outinteger(1, N × N)         comment × for multiply;
  end SQUARE;

  goto LABEL;                     comment goto exists;
  LABEL:
end
```

Key symbols:
- `:=` assignment, `=` equality test
- `∧` and, `∨` or, `¬` not
- `≠` not equal, `≤` less-or-equal, `≥` greater-or-equal
- `×` multiply, `÷` integer divide
- `begin`/`end` — block delimiters (like `{}`/`}`)
- `own` — static persistence (the key insight for sediment)

## How the Constraint Engine Maps to ALGOL 60

| Constraint Engine Concept | ALGOL 60 Mechanism |
|---------------------------|---------------------|
| Constraint table (8 constraints) | Parallel arrays: `CLO[I]`, `CHI[I]`, `CSEV[I]` — no structs |
| Error mask (8 bits) | Boolean array `VIOLATED[1:8]` |
| INT8 saturation | Comparison + clamping (no type to saturate) |
| Sediment layers | `own integer array` — persists across procedure calls |
| BFS fracture | Standard queue-based BFS with adjacency array |
| Pipeline stages | Nested `begin`/`end` blocks and procedures |

```
FLXCHECK.alg    — Core constraint checking with INT8 saturation and sediment
FLXFRACT.alg    — Fracture engine: bipartite BFS for independent blocks
FLXSEDIMNT.alg  — Sediment layer manager with own persistence
FLXMAIN.alg     — Main program wiring the full pipeline
```

## What ALGOL 60 Teaches Us

**`own` is sediment. Parallel arrays are columnar storage.** ALGOL 60 in 1960 gave us two mechanisms that we're still reinventing.

### The `own` Keyword — Persistent Sediment

`own` variables are allocated once and retain values between procedure calls. They are the first "closure-like" mechanism in any programming language. In the constraint engine, sediment layers are `own integer array`s — they survive across validation cycles.

```
own integer array SEDLO[1:8];     comment persists across calls;
own integer array SEDHI[1:8];     comment bounds corrections accumulate;
own integer SED_COUNT;            comment how many layers exist;
```

The geological metaphor writes itself:
- Constraint bounds are the **bedrock**
- Sediment layers are `own` arrays that **accumulate** on top
- Each validation cycle reads the current state (bedrock + sediment)
- Corrections persist without external storage

Sixty-six years later, we're still reinventing this: C's `static`, JavaScript closures, database transactions, microservice state stores, PLATO sediment layers. ALGOL 60 got there first.

### No Structs — Parallel Arrays

ALGOL 60 has no record/struct types. A "constraint" is represented as parallel entries across multiple arrays: `CLO[I]`, `CHI[I]`, `CSEV[I]` all represent constraint `I`. The index `I` is the identity; the arrays are projections.

This forces you to think about data as **indexed views** rather than objects. This is exactly how database normalization works. The parallel array pattern is the ancestor of columnar storage — what DuckDB, ClickHouse, and every analytical database does today.

### No Standard I/O

ALGOL 60 defined no I/O standard. Each implementation added its own (`outstring`, `outinteger`, etc.). This forces you to separate computation from presentation — the engine doesn't know or care how results are displayed.

## Files

| File | Purpose |
|------|---------|
| `FLXCHECK.alg` | Core constraint checking with INT8 saturation and sediment |
| `FLXFRACT.alg` | Fracture engine: bipartite BFS for independent blocks |
| `FLXSEDIMNT.alg` | Sediment layer manager with `own` persistence |
| `FLXMAIN.alg` | Main program wiring the full pipeline |

## Syntax Notes

These files use standard ALGOL 60 syntax (Revised Report on the Algorithmic Language ALGOL 60, 1963). Unicode symbols (∧, ∨, ¬, ≠, ≤, ≥, ÷) are standard in ALGOL 60 reports. `own` arrays declared at the `begin` block level persist for the program lifetime.

## Where to Go Next

- **flux-mumps** — MUMPS globals are what `own` wanted to be when it grew up: persistent, shared, hierarchical.
- **flux-snobol** — SNOBOL4's success/failure pattern matching is another form of ALGOL's Boolean arrays.
- **flux-cobol** — COBOL adds fixed-format records to ALGOL's parallel arrays — structs instead of projections.
- **flux-docs** — Full documentation: error masks, fracture-coalesce, sediment, thermodynamic analogy.

## Author

Forgemaster ⚒️ — Constraint Theory Ecosystem, 2026-05-19

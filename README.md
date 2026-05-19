# flux-algol — ALGOL 60 Constraint Engine

ALGOL 60 implementation of the Flux constraint validation pipeline. The mother of structured programming meets accumulated correctness.

## How to Read ALGOL 60

ALGOL 60 looks unfamiliar but is surprisingly regular:

```
comment This is a comment, ending with a semicolon;

begin
  integer X;                    comment declare integer;
  real Y;                       comment declare real;
  Boolean FLAG;                 comment declare Boolean;
  integer array A[1:10];        comment array, 1-indexed;
  own integer COUNT;            comment PERSISTENT across calls;

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
- `begin`/`end` block delimiters (like `{}`/`}`)
- `own` — static persistence (the key insight)

## What ALGOL 60 Forces You to Think About

### 1. No Structs — Parallel Arrays
ALGOL 60 has no record/struct types. A "constraint" is represented as parallel entries across multiple arrays: `CLO[I]`, `CHI[I]`, `CSEV[I]` all represent constraint `I`. This forces you to think about data as **indexed views** rather than objects. The index `I` is the identity; the arrays are projections.

This is exactly how database normalization works. The parallel array pattern is the ancestor of columnar storage.

### 2. The `own` Keyword — Sediment Persistence
`own` variables are allocated once and retain values between procedure calls. They are the first "closure-like" mechanism in any programming language.

In the constraint engine, sediment layers are `own integer array`s. They survive across validation cycles. The geological metaphor writes itself:
- Constraint bounds are the **bedrock**
- Sediment layers are `own` arrays that **accumulate** on top
- Each validation cycle reads the current state (bedrock + sediment)
- Corrections persist without external storage

### 3. No Standard I/O
ALGOL 60 defined no I/O standard. Each implementation added its own (`outstring`, `outinteger`, etc.). This forces you to separate computation from presentation — the engine doesn't know or care how results are displayed.

### 4. Procedure Value/Specification Parts
Parameters are declared with `value` (pass by value) and type specifications. This makes the calling convention explicit — you know exactly which variables are inputs vs. outputs.

## The Architectural Insight

**`own` is sediment.** ALGOL 60 in 1960 gave us a mechanism for state that persists across invocations without external storage. Sixty-six years later, we're still reinventing this pattern:

- C's `static` variables
- JavaScript closures
- Database transactions
- Microservice state stores
- PLATO sediment layers

The constraint engine's sediment system — accumulated corrections that persist and compound — is an `own` array. The language that invented structured programming also invented the mechanism for accumulated correctness.

## Files

| File | Purpose |
|------|---------|
| `FLXCHECK.alg` | Core constraint checking with INT8 saturation and sediment |
| `FLXFRACT.alg` | Fracture engine: bipartite BFS for independent blocks |
| `FLXSEDIMNT.alg` | Sediment layer manager with `own` persistence |
| `FLXMAIN.alg` | Main program wiring the full pipeline |

## Syntax Notes

These files use standard ALGOL 60 syntax (Revised Report on the Algorithmic Language ALGOL 60, 1963). Key conventions:
- Unicode symbols (∧, ∨, ¬, ≠, ≤, ≥, ÷) are standard in ALGOL 60 reports
- `outstring(1, ...)` and `outinteger(1, ...)` are informal I/O conventions
- `own` arrays declared at the `begin` block level persist for the program lifetime
- ALGOL 60 has no `return` statement — procedures assign to the procedure name for function results

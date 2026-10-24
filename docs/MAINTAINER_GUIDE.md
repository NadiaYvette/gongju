# Gongju Maintainer Guide

**Audience:** Repository maintainers and contributors.  
**Corpus Inventory:** [`docs/INDEX.md`](INDEX.md)  
**Parent Strategy:** [`docs/notes/DOC_STRATEGY.md`](notes/DOC_STRATEGY.md)  
**Commit Attribution:** [`docs/notes/COMMIT_ATTRIBUTION.md`](notes/COMMIT_ATTRIBUTION.md)  
**Upstream Infrastructure:** [`~/src/PLAN.md` §1](../../PLAN.md#1-project-skeleton-&-configuration-propagation-infrastructure-gachi)  

---

## 1. Architectural Invariants

### 1.1 The Precedence Rule (`DOC_STRATEGY.md` §4)
- **Code wins at runtime:** When documentation disagrees with code, the code defines runtime reality.
- **Notes are corrected regardless:** A stale note must be updated in the same change set.

### 1.2 Type-Level Purity & Induction
- **Zero Template Haskell at Runtime:** Combinators must resolve via pure typeclass induction over inductive Peano numbers.
- **Bidirectional Fundeps:** All composition typeclasses must maintain bidirectional functional dependencies to support backward and forward inference.
- **Zero Runtime Allocation:** Positional arrow combinators manipulate curried functions directly without heap allocation.

---

## 2. Verification Gates & Quality Control

Before committing or pushing changes, all 5 physical verification gates must pass:

```bash
./bin/gongju-verify
```

1. **Gate 1: HLint Static Analysis:** 0 hints allowed across all source packages (`.hlint.yaml`).
2. **Gate 2: Full Cabal Test Suite:** All Hspec unit tests must pass with 0 failures (`cabal test all`).
3. **Gate 3: Tagref Cross-Reference Gate:** Zero dangling references (e.g. `ref:<slug>`) and zero duplicate tags (`bin/gongju-tagref`).
4. **Gate 4: Markdown Link Integrity Gate:** Every relative link and heading anchor must resolve (`bin/gongju-linkcheck`).
5. **Gate 5: CLOC Comment Density Gate:** Comment density must satisfy strict documentation thresholds (`bin/gongju-cloc`).

---

## 3. Commit Attribution & DCO

Every commit must adhere to the Linux kernel RFC 2822 trailer format:
- Imperative summary under 72 characters.
- Body explains WHY the change was made.
- AI assistant contributions must carry `Assisted-by: <Tool> (<Provider> / <Model>)`.
- AI assistants must **never** be credited via `Co-authored-by:` or `Signed-off-by:`.

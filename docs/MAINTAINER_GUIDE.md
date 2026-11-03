# Gongju Maintainer Guide

**Audience:** Repository maintainers, reviewers, and automated release engineers.  
**Corpus Inventory:** [`docs/INDEX.md`](INDEX.md)  
**Parent Strategy:** [`docs/notes/DOC_STRATEGY.md`](notes/DOC_STRATEGY.md)  
**Commit Attribution:** [`docs/notes/COMMIT_ATTRIBUTION.md`](notes/COMMIT_ATTRIBUTION.md)  
**Upstream Infrastructure:** [`~/src/PLAN.md` §1](../../PLAN.md#1-project-skeleton-&-configuration-propagation-infrastructure-gachi)  

---

## 1. Architectural Invariants

Every change set submitted to `gongju` must preserve eight foundational architectural invariants:

### I1: The Precedence Rule (`DOC_STRATEGY.md` §4)
- **Code wins at runtime:** When documentation and implementation diverge, the running code defines runtime reality.
- **Notes are corrected regardless:** Stale documentation, comments, or design notes must be updated in the exact same change set. Silent drift is prohibited.

### I2: Pure Type-Level Induction & Zero Template Haskell
- All multi-argument combinators, composition operators, and positional manipulators must resolve via pure typeclass induction over the `Peano` data kind (`'Z`, `'S p`).
- Template Haskell is strictly prohibited for generating arity-specific instances or combinators.

### I3: Symmetrical Bidirectional Functional Dependencies
- All composition typeclasses (e.g. `ComposeN`, `FmapN`, `PrecomposeAt`, `SpliceAt`) must maintain bidirectional functional dependencies (`n b c g -> f`, `n f -> c`, `n f b -> g`).
- Type inference must propagate symmetrically: forward from input functions into composite types, and backward from expected contexts into polymorphic inputs.

### I4: In-Place Arrow Manipulation & Zero Heap Allocation
- Positional arrow combinators (`slipr`, `slipl`, `twist`) must manipulate curried function arrows `(a -> r)` directly in place.
- Intermediate tuples, lists, or boxed representations must never be introduced in the internal recursion spine.

### I5: Total Positional Disambiguation
- Argument permutations (`permute`) and positional bindings (`bindPos`, `precomposeAt`) must index zero-based argument slots, never type shapes.
- Functions containing duplicate argument types (e.g. `Int -> String -> Int -> Bool`) must be permuted without type-search ambiguity.

### I6: Alternating Parity in Contravariant Stacks
- Nested contravariant functor mapping (`contramapN`) must alternate variance at each inductive depth: odd depths reverse the arrow, while even depths cancel back to covariant mapping.

### I7: Multi-Slot Monadic Mask Preservation
- Multi-slot monadic lifting (`liftMask`) must accept arbitrary combinations of pure (`PArg`) and monadic (`MArg`) parameters in a single pass without requiring intermediate tuple packaging.

### I8: Zero-Cost Core Simplification
- Every inductive method across `gongju` must carry an explicit `{-# INLINE #-}` pragma.
- Under GHC `-O2`, all typeclass dictionaries (`$fComposeN`, `$fPermute`, etc.) and closure wrappers must simplify away completely, verified mechanically by `bin/gongju-inspect-core`.

---

## 2. The 6-Gate Physical Verification Discipline

Before pushing commits or publishing releases, all 6 physical verification gates must pass:

```bash
./bin/gongju-verify
```

| Gate | Check | Command / Tool | Invariant |
| :--- | :--- | :--- | :--- |
| **Gate 1** | HLint Static Analysis | `hlint packages/gongju*/src` | 0 hints allowed (`.hlint.yaml`) |
| **Gate 2** | Full Cabal Test Suite | `cabal test all` | 100% pass across all packages |
| **Gate 3** | Zero-Cost Core Inspection | `bin/gongju-inspect-core` | 0 residual dictionaries, 22/22 simplified |
| **Gate 4** | Tagref Cross-References | `bin/gongju-tagref` | 0 dangling references, 0 duplicate tags |
| **Gate 5** | Markdown Link Integrity | `bin/gongju-linkcheck --quiet` | 0 broken links or anchors |
| **Gate 6** | CLOC Comment Density | `bin/gongju-cloc --quiet --check` | Strict documentation comment threshold |

---

## 3. Maintainer Triage Runbooks

### Runbook A: Core Inspection Residual Dictionaries
- **Symptom:** `bin/gongju-inspect-core` reports residual dictionaries (e.g. `$fComposeN` remains in Core dump).
- **Cause:** Missing `{-# INLINE #-}` pragma on an instance method or an unspecialized recursive helper.
- **Fix:** Check that the instance method definition has `{-# INLINE <method> #-}`. Ensure that GHC `-O2` is enabled in the test cabal stanza and that recursive helpers are exposed to the inliner.

### Runbook B: Tagref Dangling References
- **Symptom:** `bin/gongju-tagref` reports `dangling reference to [ref:<tag>]`.
- **Cause:** A documentation note was renamed or deleted without updating referring files, or a typo was introduced in a citation.
- **Fix:** Run `git grep 'ref:<tag>'` to locate all citations. Either restore the missing `[tag:<tag>]` in the appropriate source file or update the citations.

### Runbook C: Markdown Link Integrity Failure
- **Symptom:** `bin/gongju-linkcheck` reports broken link `file:///...` or relative link mismatch.
- **Cause:** A referenced file was moved or a markdown anchor does not exist.
- **Fix:** Run `bin/gongju-linkcheck` without `--quiet` to see line numbers and exact failing paths. Adjust relative paths (`../`) or heading slugs.

### Runbook D: CLOC Comment Density Deficit
- **Symptom:** `bin/gongju-cloc` reports density below the target threshold.
- **Cause:** New code was introduced without corresponding Haddock documentation or architecture notes.
- **Fix:** Add top-level module documentation, Haddock comments on exposed functions/types, and architectural design notes.

### Runbook E: Hackage Release Preparation
When preparing a package for Hackage upload:
1. Verify `cabal check` produces 0 errors and 0 warnings:
   ```bash
   (cd packages/gongju && cabal check) && (cd packages/gongju-text && cabal check)
   ```
2. Ensure both `.cabal` files contain:
   - `synopsis`, `description`, `category`
   - `homepage: https://github.com/NadiaYvette/gongju`
   - `bug-reports: https://github.com/NadiaYvette/gongju/issues`
   - `extra-doc-files: README.md, CHANGELOG.md, LICENSE`
   - `source-repository head` stanza with correct `subdir`
   - `tested-with` stanza placed **before** `source-repository head`
3. Check that per-package `CHANGELOG.md`, `README.md`, and `LICENSE` files are present and up to date.
4. Run `./bin/gongju-verify` to ensure all 6 gates pass cleanly.

---

## 4. Commit Attribution & DCO Standards

Every commit must follow the Linux kernel RFC 2822 trailer format:
- Imperative summary under 72 characters.
- Body explains **why** the change was made, not just what code was edited.
- AI assistant contributions must carry an `Assisted-by:` trailer:
  ```
  Assisted-by: Antigravity (Google DeepMind / Gemini 3.8 Flash)
  ```
- AI assistants must **never** be credited via `Co-authored-by:` or `Signed-off-by:`, as only human authors certify the Developer Certificate of Origin (DCO).
- Enforced automatically by `.githooks/commit-msg`.

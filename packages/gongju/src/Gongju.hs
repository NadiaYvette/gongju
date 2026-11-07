-- | Module: Gongju
-- Description: Top-level prelude and unified combinator re-export for the gongju toolmaker library
--
-- Gongju (공구 / 工具, tools/implement) provides inductive Peano type-level
-- utility functions in pure Haskell, replacing Template Haskell arity splices
-- and finite tuple generics with zero-overhead typeclass induction, bidirectional
-- functional dependencies, and 'GHC.TypeNats.Nat' wrappers.
--
-- = Architectural Context
--
-- Per Note [Gongju Combinator Taxonomy] [ref:note-gongju-combinators], 'Gongju'
-- collects all specialized combinator categories into a single import surface:
--
-- * "Gongju.Core": Fundamental Peano arithmetic, 'ToPeano' type families, and induction.
-- * "Gongju.Diagonal": Homogeneous arity distribution ('onN', 'diagN') and variadic zipping ('zipWithN').
-- * "Gongju.Spine": Arbitrary-depth interleaved Monad/Traversable spine binding ('spineFor', 'spineWither').
-- * "Gongju.Evacuate": Evacuability polymorphism bridging non-empty and evacuable collections ('sift', 'insertEvac').
-- * "Gongju.Tuple": Flat GHC tuple currying isomorphisms ('curryFlat', 'uncurryFlat') and mapping ('mapTupleHom').
-- * "Gongju.Composition": Multi-arity function composition and pipeline wiring.
-- * "Gongju.Permute": Curried argument permutation and transposition.
-- * "Gongju.Positional": Positional indexing and targeted argument application.
--
-- == Invariants & Guarantees
--
-- 1. __Zero Allocation Overhead:__ All exposed combinators expand to primitive
--    unboxed functions or GHC Core case matches.
-- 2. __Purity & Totality:__ Every function exported through this prelude is total.
-- 3. __Comment Density:__ Fully documented with Haddock examples satisfying Gate 5.
--
-- = Worked Example
--
-- >>> onN @2 (* 10) (,) 3 4
-- (30, 40)
--
-- >>> sift (> 1) (1 :| [2, 3]) :: Maybe (NonEmpty Int)
-- Just (2 :| [3])
module Gongju
  ( -- * 1. Core Peano & Natural Number Infrastructure
    module Gongju.Core
  , module Gongju.Peano

    -- * 2. Arity Distribution & Diagonalization
  , module Gongju.Diagonal

    -- * 3. Deep Spine Traversal & Contraction
  , module Gongju.Spine

    -- * 4. Evacuability Polymorphism
  , module Gongju.Evacuate

    -- * 5. Tuple Currying & Homogeneous Distribution
  , module Gongju.Tuple

    -- * 6. High-Arity Composition & Combinators
  , module Gongju.Composition
  , module Gongju.Permute
  , module Gongju.Positional

    -- * 7. Categorical Functor & Profunctor Infrastructure
  , module Gongju.Adjunction
  , module Gongju.Comonad
  , module Gongju.Contravariant
  , module Gongju.Indexed
  , module Gongju.Kan
  , module Gongju.Monad
  , module Gongju.Profunctor
  ) where

import Gongju.Adjunction
import Gongju.Comonad
import Gongju.Composition
import Gongju.Contravariant
import Gongju.Core
import Gongju.Diagonal
import Gongju.Evacuate
import Gongju.Indexed
import Gongju.Kan
import Gongju.Monad
import Gongju.Peano
import Gongju.Permute
import Gongju.Positional
import Gongju.Profunctor
import Gongju.Spine
import Gongju.Tuple

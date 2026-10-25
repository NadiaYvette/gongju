{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeAbstractions #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Module: Gongju.Composition
-- Description: The Grand Unified Open-World Tape Engine and Variadic Composition
--
-- Provides the open tag-driven state machine ('StepPathMask', 'StepRole') for multi-stage
-- functor and arrow composition, arbitrary argument permutation ('Permute'), lax monoidal
-- zipping ('ApPath'), distributive laws ('CommutePast', 'PullPath'), and ergonomic
-- visible-forall entry points ('composeUnifiedV', 'withOps', 'infixr 9 .@').
--
-- Also preserves legacy inductive Peano arity composition ('ComposeN', 'compN') and
-- nested functor mapping ('FmapN', 'fmapN') with bidirectional functional dependencies.
module Gongju.Composition
  ( -- * Open Layer Tags
    F
  , C
  , B1
  , B2
  , BB
  , P1
  , P2
  , Fn
    -- * Open Mapping Primitives
  , MapStep(..)
  , MapPath(..)
    -- * Open Zipping Primitives
  , ApStep(..)
  , ApPath(..)
    -- * Distributive Laws & Commuting
  , CommutePair(..)
  , CommutePast(..)
  , PullPath(..)
    -- * Open State Machine & Spec Tags
  , StepRole(..)
  , StepPathMask(..)
  , type (#)
  , InOrder
  , PP
  , PZ
  , PL
  , PM
  , J
  , CS
  , SwapAt
  , PullRet
    -- * Ergonomic Unindexed Aliases
  , P
  , Z
  , M
  , L
  , LF
  , PullF
    -- * Type Families for Index & Mode Extraction
  , UnwrapMode
  , OpModes
  , HasExplicitIndex
  , OpIndices
  , OpIndicesIf
  , TakePeano
  , AtPeano
  , SwapAtPeano
    -- * Visible Forall & Infix Entry Points
  , composeUnifiedV
  , withOps
  , (.@)
    -- * Backward-Compatible Variadic Combinators
  , ComposeN(..)
  , compN
  , FmapN(..)
  , fmapN
  ) where

import Control.Monad (join)
import Data.Bifunctor (Bifunctor (bimap, first, second))
import Data.Bitraversable (Bitraversable (bitraverse), bisequenceA)
import Data.Functor.Contravariant (Contravariant (contramap))
import Data.Kind (Type)
import GHC.TypeLits (Nat)
import Gongju.Peano
  ( Append
  , Init
  , Peano (..)
  , Replicate
  , ToPeano
  )
import Gongju.Permute (Permute (..))
import Gongju.Positional (ExpectArrow)

{- Note [Variadic Composition Bidirectional Fundeps]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-variadic-composition-fundeps]
Template Haskell composition libraries (such as 'composition-extra') generate static
operators for fixed arities ((.:), (..:), (...:)). Beyond bloating code size, Template
Haskell splices cannot be abstracted over dynamically in type-level pipelines.

Gongju replaces these splices with an open tag-driven execution engine ('StepPathMask')
and inductive arity composition ('ComposeN'), indexed by Peano depth or tape masks.

Crucially, bidirectional functional dependencies are maintained across the engine:
  - @n b c g -> f@: Propagates input function types forward to determine composite function type.
  - @n f -> c@: Propagates expected output type backward into the composite structure.
  - @n f b -> g@: Infers intermediate argument shapes under polymorphic unification.
-}

-- ---------------------------------------------------------------------------
-- 1. Open Layer Tags (Extensible by Downstream Modules Without Orphans)
-- ---------------------------------------------------------------------------

-- | Covariant Functor layer tag.
data F

-- | Contravariant Functor layer tag.
data C

-- | Bifunctor first slot tag.
data B1

-- | Bifunctor second slot tag.
data B2

-- | Bifunctor diagonal tag (both slots).
data BB

-- | Profunctor first slot tag (contravariant).
data P1

-- | Profunctor second slot tag (covariant).
data P2

-- | Replicate @n@ covariant 'F' functor layers.
type Fn (n :: Nat) = Replicate n F

-- ---------------------------------------------------------------------------
-- 2. Open Primitive 1: MapStep & MapPath
-- ---------------------------------------------------------------------------

-- | 1-step mapping class dispatched on the head tag of kind 'Type'.
class MapStep (tag :: Type) (rest :: [Type]) a b s t where
  mapStep :: (a -> b) -> s -> t

-- | Sequential path mapping through a type-level stack of functor layers.
class MapPath (ls :: [Type]) a b s t where
  mapPath :: (a -> b) -> s -> t

instance (s ~ a, t ~ b) => MapPath '[] a b s t where
  mapPath f = f
  {-# INLINE mapPath #-}

instance MapStep tag ls a b s t => MapPath (tag ': ls) a b s t where
  mapPath = mapStep @tag @ls
  {-# INLINE mapPath #-}

instance (Functor φ, s ~ φ s', t ~ φ t', MapPath ls a b s' t')
  => MapStep F ls a b s t where
  mapStep f = fmap (mapPath @ls f)
  {-# INLINE mapStep #-}

instance (Contravariant φ, s ~ φ s', t ~ φ t', MapPath ls a b t' s')
  => MapStep C ls a b s t where
  mapStep f = contramap (mapPath @ls f)
  {-# INLINE mapStep #-}

instance (Bifunctor p, s ~ p s' c, t ~ p t' c, MapPath ls a b s' t')
  => MapStep B1 ls a b s t where
  mapStep f = first (mapPath @ls f)
  {-# INLINE mapStep #-}

instance (Bifunctor p, s ~ p c s', t ~ p c t', MapPath ls a b s' t')
  => MapStep B2 ls a b s t where
  mapStep f = second (mapPath @ls f)
  {-# INLINE mapStep #-}

instance (Bifunctor p, s ~ p s' s', t ~ p t' t', MapPath ls a b s' t')
  => MapStep BB ls a b s t where
  mapStep f = let g = mapPath @ls f in bimap g g
  {-# INLINE mapStep #-}

-- ---------------------------------------------------------------------------
-- 3. Open Primitive 2: ApStep & ApPath (Lax Monoidal Zipping)
-- ---------------------------------------------------------------------------

-- | 1-step applicative zipping class dispatched on layer tag.
class ApStep (tag :: Type) (rest :: [Type]) fab fa fb where
  apStep :: fab -> fa -> fb

-- | Sequential applicative zipping along a stack of functor layers.
class ApPath (ls :: [Type]) fab fa fb where
  apPath :: fab -> fa -> fb

instance (fab ~ (fa -> fb)) => ApPath '[] fab fa fb where
  apPath = id
  {-# INLINE apPath #-}

instance ApStep tag ls fab fa fb => ApPath (tag ': ls) fab fa fb where
  apPath = apStep @tag @ls
  {-# INLINE apPath #-}

instance (Applicative φ, fab ~ φ fab', fa ~ φ fa', fb ~ φ fb', ApPath ls fab' fa' fb')
  => ApStep F ls fab fa fb where
  apStep = liftA2 (apPath @ls)
  {-# INLINE apStep #-}

instance (Applicative (p c), fab ~ p c fab', fa ~ p c fa', fb ~ p c fb', ApPath ls fab' fa' fb')
  => ApStep B2 ls fab fa fb where
  apStep = liftA2 (apPath @ls)
  {-# INLINE apStep #-}

-- ---------------------------------------------------------------------------
-- 4. Open Primitive 3: CommutePair & PullPath (Distributive Laws)
-- ---------------------------------------------------------------------------

-- | Commute adjacent effect layers @l1@ and @l2@.
class CommutePair (l1 :: Type) (l2 :: Type) s t where
  commutePair :: s -> t

instance (Traversable φ, Applicative ψ, s ~ φ (ψ inner), t ~ ψ (φ inner))
  => CommutePair F F s t where
  commutePair = sequenceA
  {-# INLINE commutePair #-}

instance (Bitraversable p, Applicative ψ, s ~ p c (ψ inner), t ~ ψ (p c inner))
  => CommutePair B2 F s t where
  commutePair = bitraverse pure id
  {-# INLINE commutePair #-}

instance (Bitraversable p, Applicative ψ, s ~ p (ψ inner) c, t ~ ψ (p inner c))
  => CommutePair B1 F s t where
  commutePair = bitraverse id pure
  {-# INLINE commutePair #-}

instance (Bitraversable p, Applicative ψ, s ~ p (ψ inner) (ψ inner), t ~ ψ (p inner inner))
  => CommutePair BB F s t where
  commutePair = bisequenceA
  {-# INLINE commutePair #-}

-- | Bubble an inner layer @r@ outward past an entire @outer@ stack.
class CommutePast (outer :: [Type]) (r :: Type) s t where
  commutePast :: s -> t

instance (s ~ t) => CommutePast '[] r s t where
  commutePast = id
  {-# INLINE commutePast #-}

instance forall l ls r s mid t subS subT.
  ( CommutePast ls r subS subT
  , MapPath '[ l ] subS subT s mid
  , CommutePair l r mid t
  ) => CommutePast (l ': ls) r s t where
  commutePast = commutePair @l @r @mid @t . mapPath @'[ l ] @subS @subT @s @mid (commutePast @ls @r @subS @subT)
  {-# INLINE commutePast #-}

-- | Pull an entire @retPath@ stack outward past @outer@.
class PullPath (outer :: [Type]) (retPath :: [Type]) s t where
  pullPath :: s -> t

instance (s ~ t) => PullPath outer '[] s t where
  pullPath = id
  {-# INLINE pullPath #-}

instance forall outer r rs s mid t subS subT.
  ( CommutePast outer r s mid
  , PullPath outer rs subS subT
  , MapPath '[ r ] subS subT mid t
  ) => PullPath outer (r ': rs) s t where
  pullPath = mapPath @'[ r ] @subS @subT @mid @t (pullPath @outer @rs @subS @subT) . commutePast @outer @r @s @mid
  {-# INLINE pullPath #-}

-- ---------------------------------------------------------------------------
-- 5. Open Primitive 4: StepRole & StepPathMask (The Open State Machine)
-- ---------------------------------------------------------------------------

-- | Individual operational step executing a transition on the accumulator.
class StepRole (op :: Type) (base :: [Type]) (active :: [Type]) (ms :: [Type]) m t3 acc out where
  stepRole :: (m -> t3) -> acc -> out

-- | Tape machine executing a list of operations @ms@ against the active functor stack.
class StepPathMask (base :: [Type]) (active :: [Type]) (ms :: [Type]) m t3 acc out where
  stepPathMask :: (m -> t3) -> acc -> out

instance (acc ~ m, out ~ t3) => StepPathMask base active '[] m t3 acc out where
  stepPathMask f acc = f acc
  {-# INLINE stepPathMask #-}

instance StepRole op base active ms m t3 acc out
  => StepPathMask base active (op ': ms) m t3 acc out where
  stepPathMask = stepRole @op @base @active @ms
  {-# INLINE stepPathMask #-}

-- | Open spec tag pairing an explicit argument index with a mode.
infix 6 #
data (i :: Nat) # (mode :: Type)

-- | Open spec tag for unindexed in-order arguments.
data InOrder (mode :: Type)

-- | Pure argument mode tag.
data PP

-- | Applicative zipped argument mode tag.
data PZ

-- | Layered argument mode tag along sub-stack @sub@.
data PL (sub :: [Type])

-- | Monadic bind argument mode tag.
data PM

-- | Monadic return join tag.
data J

-- | Collapse 2 innermost monadic layers.
data CS

-- | Swap active layers at depth @d@ and @d + 1@.
data SwapAt (d :: Nat)

-- | Commute @retPath@ outward past @active@.
data PullRet (retPath :: [Type])

-- Ergonomic unindexed aliases:
type P = InOrder PP
type Z = InOrder PZ
type M = InOrder PM
type L (ls :: [Type]) = InOrder (PL ls)
type LF (n :: Nat) = InOrder (PL (Fn n))
type PullF (n :: Nat) = PullRet (Fn n)

-- | Recursively unwrap indexed or in-order wrapper tags into underlying modes.
type family UnwrapMode (op :: Type) :: Type where
  UnwrapMode (_ # mode) = UnwrapMode mode
  UnwrapMode (InOrder mode) = UnwrapMode mode
  UnwrapMode stackOp = stackOp

-- | Map 'UnwrapMode' across a list of operation tags.
type family OpModes (ops :: [Type]) :: [Type] where
  OpModes '[] = '[]
  OpModes (op ': ops) = UnwrapMode op ': OpModes ops

-- | Detect whether any operation in the list specifies an explicit numerical index.
type family HasExplicitIndex (ops :: [Type]) :: Bool where
  HasExplicitIndex '[] = 'False
  HasExplicitIndex ((_ # _) ': _) = 'True
  HasExplicitIndex (_ ': ops) = HasExplicitIndex ops

-- | Extract the list of indices from an operation list if explicitly indexed.
type family OpIndices (ops :: [Type]) :: [Peano] where
  OpIndices ops = OpIndicesIf (HasExplicitIndex ops) ops

-- | Helper family generating the index list depending on explicit tagging.
type family OpIndicesIf (indexed :: Bool) (ops :: [Type]) :: [Peano] where
  OpIndicesIf 'False _ = '[]
  OpIndicesIf 'True '[] = '[]
  OpIndicesIf 'True ((i # _) ': ops) = ToPeano i ': OpIndicesIf 'True ops
  OpIndicesIf 'True (InOrder _ ': ops) = 'Z ': OpIndicesIf 'True ops
  OpIndicesIf 'True (_ ': ops) = OpIndicesIf 'True ops

-- | Take @d@ elements from a type-level list.
type family TakePeano (d :: Peano) (xs :: [k]) :: [k] where
  TakePeano 'Z _ = '[]
  TakePeano ('S d) (x ': xs) = x ': TakePeano d xs

-- | Index into a type-level list at Peano position @d@.
type family AtPeano (d :: Peano) (xs :: [k]) :: k where
  AtPeano 'Z (x ': _) = x
  AtPeano ('S d) (_ ': xs) = AtPeano d xs

-- | Swap adjacent elements in a type-level list at depth @d@.
type family SwapAtPeano (d :: Peano) (xs :: [k]) :: [k] where
  SwapAtPeano 'Z (x ': y ': xs) = y ': x ': xs
  SwapAtPeano ('S d) (x ': xs) = x ': SwapAtPeano d xs

-- Core StepRole Instances:

instance (ExpectArrow "StepRole PP" acc a rTail, StepPathMask base '[] ms m t3 rTail out')
  => StepRole PP base '[] ms m t3 acc (a -> out') where
  stepRole f acc a = stepPathMask @base @'[] @ms f (acc a)
  {-# INLINE stepRole #-}

instance forall base l ls ms m t3 acc acc' out' a rTail.
  ( MapPath (l ': ls) (a -> rTail) rTail acc acc'
  , StepPathMask base (l ': ls) ms m t3 acc' out'
  ) => StepRole PP base (l ': ls) ms m t3 acc (a -> out') where
  stepRole f acc a =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out'
      f
      (mapPath @(l ': ls) @(a -> rTail) @rTail @acc @acc' ($ a) acc)
  {-# INLINE stepRole #-}

instance (ExpectArrow "StepRole PZ" acc a rTail, MapPath base a rTail fa acc', StepPathMask base base ms m t3 acc' out')
  => StepRole PZ base '[] ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @base @ms @m @t3 @acc' @out' f (mapPath @base acc fa)
  {-# INLINE stepRole #-}

instance (ApPath (l ': ls) acc fa acc', StepPathMask base (l ': ls) ms m t3 acc' out')
  => StepRole PZ base (l ': ls) ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out' f (apPath @(l ': ls) acc fa)
  {-# INLINE stepRole #-}

instance forall base active sub ms m t3 acc acc' out' a rTail fa inner.
  ( MapPath sub a rTail fa inner
  , MapPath active (a -> rTail) inner acc acc'
  , StepPathMask base (Append active sub) ms m t3 acc' out'
  ) => StepRole (PL sub) base active ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @(Append active sub) @ms @m @t3 @acc' @out' f
      (mapPath @active @(a -> rTail) @inner @acc @acc' (\k -> mapPath @sub @a @rTail @fa @inner k fa) acc)
  {-# INLINE stepRole #-}

instance (Monad φ, ExpectArrow "StepRole PM" acc a rTail, fa ~ φ a, StepPathMask base '[ F ] ms m t3 (φ rTail) out')
  => StepRole PM base '[] ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @'[ F ] @ms f (fmap acc fa)
  {-# INLINE stepRole #-}

instance forall base l ls ms m t3 acc acc' out' φ a rTail fa.
  ( Monad φ, fa ~ φ a
  , MapPath (Init (l ': ls)) (φ (a -> rTail)) (φ rTail) acc acc'
  , StepPathMask base (l ': ls) ms m t3 acc' out'
  ) => StepRole PM base (l ': ls) ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out' f
      (mapPath @(Init (l ': ls)) @(φ (a -> rTail)) @(φ rTail) (\mf -> mf >>= (<$> fa)) acc)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out φ inner.
  ( Monad φ
  , MapPath (Init active) (φ (φ inner)) (φ inner) acc acc'
  , StepPathMask base active ms m t3 acc' out
  ) => StepRole J base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @active @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(φ (φ inner)) @(φ inner) join acc)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out φ inner.
  ( Monad φ
  , MapPath (Init (Init active)) (φ (φ inner)) (φ inner) acc acc'
  , StepPathMask base (Init active) ms m t3 acc' out
  ) => StepRole CS base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Init active) @ms @m @t3 @acc' @out f
      (mapPath @(Init (Init active)) @(φ (φ inner)) @(φ inner) join acc)
  {-# INLINE stepRole #-}

instance forall (d :: Nat) base active ms m t3 acc acc' out sMid tMid dp.
  ( dp ~ ToPeano d
  , CommutePair (AtPeano dp active) (AtPeano ('S dp) active) sMid tMid
  , MapPath (TakePeano dp active) sMid tMid acc acc'
  , StepPathMask base (SwapAtPeano dp active) ms m t3 acc' out
  ) => StepRole (SwapAt d) base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(SwapAtPeano dp active) @ms @m @t3 @acc' @out f
      (mapPath @(TakePeano dp active) @sMid @tMid
        (commutePair @(AtPeano dp active) @(AtPeano ('S dp) active) @sMid @tMid) acc)
  {-# INLINE stepRole #-}

instance forall (retPath :: [Type]) base active ms m t3 acc acc' out.
  ( PullPath active retPath acc acc'
  , StepPathMask base (Append retPath active) ms m t3 acc' out
  ) => StepRole (PullRet retPath) base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Append retPath active) @ms @m @t3 @acc' @out f
      (pullPath @active @retPath @acc @acc' acc)
  {-# INLINE stepRole #-}

-- ---------------------------------------------------------------------------
-- 6. Visible-Forall & Infix Entry Points
-- ---------------------------------------------------------------------------

-- | Fully general visible-forall composition engine parameterized by lifting path, base, and op tape.
composeUnifiedV ::
  forall (lpath :: [Type]) ->
  forall (base :: [Type]) ->
  forall (ops :: [Type]) ->
  forall a t3 m m' g gPerm out.
  ( Permute (OpIndices ops) g gPerm
  , MapPath lpath a t3 m m'
  , StepPathMask base '[] (OpModes ops) m m' gPerm out
  ) =>
  (a -> t3) -> g -> out
composeUnifiedV (type lpath) (type base) (type ops) @a @t3 @m @m' @g @gPerm @out f g =
  stepPathMask @base @'[] @(OpModes ops) @m @m' @gPerm @out
    (mapPath @lpath @a @t3 @m @m' f)
    (permute' @(OpIndices ops) @g @gPerm g)
{-# INLINE composeUnifiedV #-}

-- | Execute an outer function over an inner function with an open operation tape.
withOps ::
  forall (ops :: [Type]) ->
  forall m t3 g gPerm out.
  ( Permute (OpIndices ops) g gPerm
  , StepPathMask '[] '[] (OpModes ops) m t3 gPerm out
  ) =>
  (m -> t3) -> g -> out
withOps (type ops) @m @t3 @g @gPerm @out f g =
  stepPathMask @'[] @'[] @(OpModes ops) @m @t3 @gPerm @out
    f
    (permute' @(OpIndices ops) @g @gPerm g)
{-# INLINE withOps #-}

-- | Infix tape-driven composition operator.
--
-- Example:
--
-- >>> (show .@ [P, P]) (+) 10 20
-- "30"
infixr 9 .@
(.@) ::
  forall m t3 g gPerm out.
  (m -> t3) ->
  forall (ops :: [Type]) ->
  ( Permute (OpIndices ops) g gPerm
  , StepPathMask '[] '[] (OpModes ops) m t3 gPerm out
  ) =>
  g -> out
((.@) f (type ops)) g = withOps ops f g
{-# INLINE (.@) #-}

-- ---------------------------------------------------------------------------
-- 7. Backward-Compatible Variadic Arity Composition
-- ---------------------------------------------------------------------------

-- | Inductive arity composition class parameterized over Peano depth @n@.
--
-- See Note [Variadic Composition Bidirectional Fundeps] [ref:note-variadic-composition-fundeps].
class ComposeN (n :: Peano) b c g f | n b c g -> f, n f -> c, n f b -> g where
  -- | Internal composition worker operating on inductive 'Peano' terms.
  composeN' :: (b -> c) -> g -> f

instance ComposeN 'Z b c b c where
  composeN' f x = f x
  {-# INLINE composeN' #-}

instance ComposeN n b c r r' => ComposeN ('S n) b c (a -> r) (a -> r') where
  composeN' f g a = composeN' @n f (g a)
  {-# INLINE composeN' #-}

-- | Compose a unary function @(b -> c)@ with a curried function consuming @n@ arguments.
--
-- Examples:
--
-- @
-- compN @1 == (.)
-- compN @2 == (.:)
-- compN @3 == (..:)
-- @
compN :: forall (n :: Nat) b c g f. ComposeN (ToPeano n) b c g f => (b -> c) -> g -> f
compN = composeN' @(ToPeano n)
{-# INLINE compN #-}

-- | Inductive nested functor mapping class parameterized over nesting depth @n@.
class FmapN (n :: Peano) a b s t | n a b s -> t, n s t -> a b where
  -- | Internal functor mapping worker operating on inductive 'Peano' terms.
  fmapN' :: (a -> b) -> s -> t

instance FmapN 'Z a b a b where
  fmapN' f = f
  {-# INLINE fmapN' #-}

instance (Functor f, FmapN n a b s t) => FmapN ('S n) a b (f s) (f t) where
  fmapN' f = fmap (fmapN' @n f)
  {-# INLINE fmapN' #-}

-- | Map a transformation @(a -> b)@ through @n@ nested 'Functor' layers.
fmapN :: forall (n :: Nat) a b s t. FmapN (ToPeano n) a b s t => (a -> b) -> s -> t
fmapN = fmapN' @(ToPeano n)
{-# INLINE fmapN #-}

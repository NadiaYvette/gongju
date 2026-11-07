{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneKindSignatures #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Spine
-- Description: Arbitrary-depth interleaved Monad, Traversable, and Witherable spine traversal
--
-- This module implements zero-overhead arbitrary-depth spine traversal and contraction
-- combinators ('spineFor', 'forMN', 'spineWither', 'witherMN') over complex nested
-- monadic and traversable spines, eliminating nested @traverse . traverse@ and
-- @forMMMM@ boilerplate across multi-layered data structures.
--
-- = Architectural Context
--
-- Per Note [Spine Traversal Invariants] [ref:note-spine-traversal], working with
-- deeply nested effectful data pipelines (e.g., @IO [[Text]]@ or @Eff es [Seq a]@)
-- frequently leads to fragile, manual nesting of 'traverse' and monadic joins.
-- 'Gongju.Spine' provides a closed type family 'ClassifyLayer' that disambiguates
-- between the enclosing Monad @m@, an intermediate Traversable @t@, and the target
-- element layer at compile time without requiring overlapping typeclass instances.
--
-- == Invariants & Guarantees
--
-- 1. __Zero Overlapping Instances:__ By driving resolution through 'ClassifyLayer',
--    all instance selections are deterministic and strictly disjoint.
-- 2. __Automated Layer Fusion:__ Intermediate monadic actions are fused via @(>>=)@,
--    while traversable layers distribute via 'traverse' and witherable layers contract
--    via 'wither' in a single pass.
-- 3. __Totality & Inlining:__ All recursive operations expand to primitive GHC Core
--    binds and traverses via @{-# INLINE #-}@ pragmas.
--
-- = Worked Examples
--
-- >>> spineFor @2 (pure [[1, 2], [3]] :: IO [[Int]]) (pure . sum)
-- [3, 3]
--
-- >>> spineFor @3 (pure [[1, 2], [3]] :: IO [[Int]]) (pure . (* 10))
-- [[10, 20], [30]]
--
-- >>> spineWither @1 (pure [Just 1, Nothing, Just 3] :: IO [Maybe Int]) pure
-- [1, 3]
module Gongju.Spine
  ( -- * 1. Closed Type-Family Layer Classifier (Zero OverlappingInstances)
    LayerTag (..)
  , ClassifyLayer
    -- * 2. Arbitrary-Depth Interleaved Monad/Traversable Binding (`spineFor`, `forMN`)
  , SpineBind (..)
  , spineFor
  , forMN
    -- * 3. Arbitrary-Depth Witherable/Filterable Contraction (`spineWither`, `witherMN`)
  , SpineWither (..)
  , spineWither
  , witherMN
  ) where

import Data.Kind (Type)
import GHC.TypeNats (Nat)
import Witherable (Witherable (..))

import Gongju.Core (Peano (..), ToPeano)

{- Note [Spine Traversal]
~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-spine-traversal]
Arbitrary-depth spine traversal performs depth-indexed interleaved monadic binding and
traversable distribution, peeling d outer layers to apply morphisms or withering predicates
at the leaf element with zero intermediate allocations.
-}

--------------------------------------------------------------------------------
-- 1. Disjoint Layer Classification
--------------------------------------------------------------------------------

-- | Classifies the role of an outer layer at depth @d@ relative to the target monad @m@.
data LayerTag
  = LayerTarget      -- ^ Depth 0: reached the element/container target
  | LayerMonad       -- ^ Outer layer is the active Monad @m@ itself (@join@ / @=<<@)
  | LayerTraversable -- ^ Outer layer is another Traversable @t@ (@traverse@)

-- | Closed type family inspecting a type representation to determine its 'LayerTag'
--   at depth @d@ with respect to active monad @m@.
type ClassifyLayer :: Peano -> (Type -> Type) -> Type -> LayerTag
type family ClassifyLayer d m spine where
  ClassifyLayer 'Z     _ _         = 'LayerTarget
  ClassifyLayer ('S _) m (m _)     = 'LayerMonad
  ClassifyLayer ('S _) _ (_ _)     = 'LayerTraversable

--------------------------------------------------------------------------------
-- 2. Arbitrary-Depth Monad + Traversable Spine Traversal (`spineFor` / `forMN`)
--------------------------------------------------------------------------------

-- | Typeclass performing depth-indexed interleaved monadic and traversable traversal.
--
--   Inductively peels @d@ layers off @spine@, distributing intermediate @t@ layers
--   and binding intermediate @m@ layers until the leaf element @a@ is reached.
class SpineBind (d :: Peano) (tag :: LayerTag) (m :: Type -> Type) spine a b out
  | d tag m spine b -> out
  , d tag m spine -> a
  where
  -- | Core inductive worker for 'spineFor'.
  spineBindPeano :: Monad m => spine -> (a -> m b) -> m out

-- | Base case (d = 'Z): apply @a -> m b@ directly to the leaf element.
instance SpineBind 'Z 'LayerTarget m a a b b where
  spineBindPeano x f = f x
  {-# INLINE spineBindPeano #-}

-- | Inductive step 1: outer layer is @m@ itself -> bind via @(>>=)@.
instance ( nextTag ~ ClassifyLayer d m inner
         , SpineBind d nextTag m inner a b out
         )
      => SpineBind ('S d) 'LayerMonad m (m inner) a b out where
  spineBindPeano mx f = mx >>= \inner -> spineBindPeano @d @nextTag inner f
  {-# INLINE spineBindPeano #-}

-- | Inductive step 2: outer layer is a Traversable @t@ -> distribute via @traverse@.
instance ( Traversable t
         , nextTag ~ ClassifyLayer d m inner
         , SpineBind d nextTag m inner a b out
         )
      => SpineBind ('S d) 'LayerTraversable m (t inner) a b (t out) where
  spineBindPeano tx f = traverse (\inner -> spineBindPeano @d @nextTag inner f) tx
  {-# INLINE spineBindPeano #-}

-- | Traverses @d@ nested layers of @Monad m@ and @Traversable t@, applying
--   @a -> m b@ at depth @d@ and fusing all @m@ layers automatically.
--
--   >>> spineFor @2 (pure [[1, 2], [3]] :: IO [[Int]]) (pure . sum)
--   [3, 3] :: IO [Int]
--
--   >>> spineFor @3 (pure [[1, 2], [3]] :: IO [[Int]]) (pure . (* 10))
--   [[10, 20], [30]] :: IO [[Int]]
{-# INLINE spineFor #-}
spineFor
  :: forall (d :: Nat) m spine a b out.
     ( Monad m
     , SpineBind (ToPeano d) (ClassifyLayer (ToPeano d) m spine) m spine a b out
     )
  => spine -> (a -> m b) -> m out
spineFor = spineBindPeano @(ToPeano d) @(ClassifyLayer (ToPeano d) m spine)

-- | Flipped alias of 'spineFor' matching standard @mapM@ argument order.
{-# INLINE forMN #-}
forMN
  :: forall (d :: Nat) m spine a b out.
     ( Monad m
     , SpineBind (ToPeano d) (ClassifyLayer (ToPeano d) m spine) m spine a b out
     )
  => (a -> m b) -> spine -> m out
forMN = flip (spineFor @d)

--------------------------------------------------------------------------------
-- 3. Arbitrary-Depth Witherable Spine Contraction (`spineWither` / `witherMN`)
--------------------------------------------------------------------------------

-- | Typeclass performing depth-indexed spine withering and contraction.
--
--   Descends @d@ outer layers to locate a 'Witherable' container, applying
--   @a -> m (Maybe b)@ and evaporating filtered elements at the leaf level.
class SpineWither (d :: Peano) (tag :: LayerTag) (m :: Type -> Type) spine a b out
  | d tag m spine b -> out
  , d tag m spine -> a
  where
  -- | Core inductive worker for 'spineWither'.
  spineWitherPeano :: Monad m => spine -> (a -> m (Maybe b)) -> m out

-- | Base case (d = 'Z): target @w a@ is a Witherable container.
instance Witherable w => SpineWither 'Z 'LayerTarget m (w a) a b (w b) where
  spineWitherPeano wx f = wither f wx
  {-# INLINE spineWitherPeano #-}

-- | Inductive step 1: outer layer is @m@ itself -> bind via @(>>=)@.
instance ( nextTag ~ ClassifyLayer d m inner
         , SpineWither d nextTag m inner a b out
         )
      => SpineWither ('S d) 'LayerMonad m (m inner) a b out where
  spineWitherPeano mx f = mx >>= \inner -> spineWitherPeano @d @nextTag inner f
  {-# INLINE spineWitherPeano #-}

-- | Inductive step 2: outer layer is a Traversable @t@ -> distribute via @traverse@.
instance ( Traversable t
         , nextTag ~ ClassifyLayer d m inner
         , SpineWither d nextTag m inner a b out
         )
      => SpineWither ('S d) 'LayerTraversable m (t inner) a b (t out) where
  spineWitherPeano tx f = traverse (\inner -> spineWitherPeano @d @nextTag inner f) tx
  {-# INLINE spineWitherPeano #-}

-- | Descends @d@ outer layers of @Monad m@ / @Traversable t@ to a 'Witherable'
--   container @w a@, withering it with @a -> m (Maybe b)@ in a single pass.
--
--   Solves the @No instance for Witherable IO@ error directly:
--   >>> spineWither @1 (pure [Just 1, Nothing, Just 3] :: IO [Maybe Int]) pure
--   [1, 3] :: IO [Int]
{-# INLINE spineWither #-}
spineWither
  :: forall (d :: Nat) m spine a b out.
     ( Monad m
     , SpineWither (ToPeano d) (ClassifyLayer (ToPeano d) m spine) m spine a b out
     )
  => spine -> (a -> m (Maybe b)) -> m out
spineWither = spineWitherPeano @(ToPeano d) @(ClassifyLayer (ToPeano d) m spine)

-- | Flipped alias of 'spineWither' matching @for@ / @wither@ argument order.
{-# INLINE witherMN #-}
witherMN
  :: forall (d :: Nat) m spine a b out.
     ( Monad m
     , SpineWither (ToPeano d) (ClassifyLayer (ToPeano d) m spine) m spine a b out
     )
  => (a -> m (Maybe b)) -> spine -> m out
witherMN = flip (spineWither @d)

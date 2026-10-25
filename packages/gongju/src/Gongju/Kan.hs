{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Module: Gongju.Kan
-- Description: Kan Extensions, Yoneda, and Codensity Fusion for Gongju
--
-- Integrates Right and Left Kan extensions ('Ran', 'Lan'), Yoneda lemma embeddings
-- ('Yoneda', 'Coyoneda'), and Codensity / Density monad-comonad generators
-- ('Codensity', 'Density') from 'kan-extensions' into Gongju's open tape composition engine.
--
-- Enables:
-- * Structural Kan rewrites without typeclass constraints on @g@ or @h@.
-- * $O(1)$ functor mapping fusion via 'Yoneda' and 'Coyoneda'.
-- * $O(1)$ monad bind optimization via 'Codensity' CPS transformations.
module Gongju.Kan
  ( -- * Re-exported Canonical Kan Types
    Lan(..)
  , Ran(..)
  , toRan
  , fromRan
  , Yoneda(..)
  , liftYoneda
  , lowerYoneda
  , Coyoneda(..)
  , liftCoyoneda
  , lowerCoyoneda
  , Codensity(..)
  , liftCodensity
  , lowerCodensity
  , Density(..)
  , liftDensity
  , lowerDensity
    -- * Kan Structural Unit & Counit Operations
  , ranCounit
  , ranUnit
  , lanUnit
  , lanCounit
    -- * Open Kan Tags
  , PRanC
  , PRanU
  , PLanU
  , PLanC
  , PCoY
  , PUnCoY
  , PYon
  , PUnYon
  , PCodM
  , PUnCod
  , PDenW
  , PUnDen
    -- * Ergonomic Aliases
  , RanC
  , RanU
  , LanU
  , LanC
  , CoY
  , UnCoY
  , Yon
  , UnYon
  , CodM
  , UnCod
  , DenW
  , UnDen
  ) where

import Control.Comonad (Comonad, extend)
import Control.Comonad.Density
  ( Density (..)
  , liftDensity
  )
import Control.Monad.Codensity
  ( Codensity (..)
  , lowerCodensity
  )
import Data.Functor.Coyoneda
  ( Coyoneda (..)
  , liftCoyoneda
  , lowerCoyoneda
  )
import Data.Functor.Kan.Lan
  ( Lan (..)
  )
import Data.Functor.Kan.Ran
  ( Ran (..)
  , fromRan
  , toRan
  )
import Data.Functor.Yoneda
  ( Yoneda (..)
  , liftYoneda
  , lowerYoneda
  )
import Gongju.Composition
  ( F
  , InOrder
  , MapPath (..)
  , StepPathMask (..)
  , StepRole (..)
  )
import Gongju.Peano (Append, Init)
import Gongju.Positional (ExpectArrow)

-- ---------------------------------------------------------------------------
-- 1. Kan Universal Unit & Counit Operations
-- ---------------------------------------------------------------------------

-- | Universal Counit of Ran: @Ran g h (g a) -> h a@ (zero constraints).
ranCounit :: Ran g h (g a) -> h a
ranCounit (Ran k) = k id
{-# INLINE ranCounit #-}

-- | Identity Unit of Ran: @a -> Ran g g a@ (zero constraints).
ranUnit :: a -> Ran g g a
ranUnit a = Ran ($ a)
{-# INLINE ranUnit #-}

-- | Universal Unit of Lan: @h a -> Lan g h (g a)@ (zero constraints).
lanUnit :: h a -> Lan g h (g a)
lanUnit ha = Lan id ha
{-# INLINE lanUnit #-}

-- | Identity Counit of Lan: @Lan g g a -> a@ (zero constraints).
lanCounit :: Lan g g a -> a
lanCounit (Lan f ga) = f ga
{-# INLINE lanCounit #-}

-- | Lift a monadic action into 'Codensity' for CPS fusion.
liftCodensity :: Monad m => m a -> Codensity m a
liftCodensity m = Codensity (m >>=)
{-# INLINE liftCodensity #-}

-- | Lower 'Density' back into the underlying comonad.
lowerDensity :: Comonad w => Density w a -> w a
lowerDensity (Density f wb) = extend f wb
{-# INLINE lowerDensity #-}

-- ---------------------------------------------------------------------------
-- 2. Open Mode Tags & Aliases
-- ---------------------------------------------------------------------------

-- | Tag for Ran Counit: collapses @Ran g h (g inner) -> h inner@.
data PRanC

-- | Tag for Ran Unit: expands @inner -> Ran g g inner@.
data PRanU

-- | Tag for Lan Unit: expands @h inner -> Lan g h (g inner)@.
data PLanU

-- | Tag for Lan Counit: collapses @Lan g g inner -> inner@.
data PLanC

-- | Tag for lifting arguments into 'Coyoneda'.
data PCoY

-- | Tag for lowering 'Coyoneda' via single 'fmap'.
data PUnCoY

-- | Tag for lifting arguments into 'Yoneda'.
data PYon

-- | Tag for lowering 'Yoneda' into the underlying functor.
data PUnYon

-- | Tag for lifting monadic arguments into 'Codensity'.
data PCodM

-- | Tag for lowering 'Codensity' back to the underlying monad.
data PUnCod

-- | Tag for lifting comonadic arguments into 'Density'.
data PDenW

-- | Tag for lowering 'Density' back to the underlying comonad.
data PUnDen

-- | In-order Ran Counit alias.
type RanC = InOrder PRanC

-- | In-order Ran Unit alias.
type RanU = InOrder PRanU

-- | In-order Lan Unit alias.
type LanU = InOrder PLanU

-- | In-order Lan Counit alias.
type LanC = InOrder PLanC

-- | In-order Coyoneda lifting alias.
type CoY = InOrder PCoY

-- | In-order Coyoneda lowering alias.
type UnCoY = InOrder PUnCoY

-- | In-order Yoneda lifting alias.
type Yon = InOrder PYon

-- | In-order Yoneda lowering alias.
type UnYon = InOrder PUnYon

-- | In-order Codensity lifting alias.
type CodM = InOrder PCodM

-- | In-order Codensity lowering alias.
type UnCod = InOrder PUnCod

-- | In-order Density lifting alias.
type DenW = InOrder PDenW

-- | In-order Density lowering alias.
type UnDen = InOrder PUnDen

-- ---------------------------------------------------------------------------
-- 3. StepRole Instances (Kan Extensions & Yoneda Fusion)
-- ---------------------------------------------------------------------------

-- | Ran Counit: collapses @Ran g h (g inner)@ to @h inner@ at the tip.
instance forall base active ms m t3 acc acc' out g h inner.
  ( MapPath (Init (Init active)) (Ran g h (g inner)) (h inner) acc acc'
  , StepPathMask base (Init active) ms m t3 acc' out
  ) => StepRole PRanC base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Init active) @ms @m @t3 @acc' @out f
      (mapPath @(Init (Init active)) @(Ran g h (g inner)) @(h inner) ranCounit acc)
  {-# INLINE stepRole #-}

-- | Ran Unit: inserts @Ran g g@ around @inner@.
instance forall base active ms m t3 acc acc' out g inner.
  ( MapPath active inner (Ran g g inner) acc acc'
  , StepPathMask base (Append active '[ F ]) ms m t3 acc' out
  ) => StepRole PRanU base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Append active '[ F ]) @ms @m @t3 @acc' @out f
      (mapPath @active @inner @(Ran g g inner) ranUnit acc)
  {-# INLINE stepRole #-}

-- | Lan Unit: expands @h inner@ to @Lan g h (g inner)@.
instance forall base active ms m t3 acc acc' out g h inner.
  ( MapPath (Init active) (h inner) (Lan g h (g inner)) acc acc'
  , StepPathMask base (Append active '[ F ]) ms m t3 acc' out
  ) => StepRole PLanU base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Append active '[ F ]) @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(h inner) @(Lan g h (g inner)) lanUnit acc)
  {-# INLINE stepRole #-}

-- | Lan Counit: collapses @Lan g g inner@ to @inner@.
instance forall base active ms m t3 acc acc' out g inner.
  ( MapPath (Init active) (Lan g g inner) inner acc acc'
  , StepPathMask base (Init active) ms m t3 acc' out
  ) => StepRole PLanC base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Init active) @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(Lan g g inner) @inner lanCounit acc)
  {-# INLINE stepRole #-}

-- | Coyoneda lifting: wraps argument in 'Coyoneda' with zero constraints.
instance (ExpectArrow "StepRole PCoY" acc (Coyoneda φ a) rTail, fa ~ φ a, StepPathMask base '[] ms m t3 rTail out')
  => StepRole PCoY base '[] ms m t3 acc (fa -> out') where
  stepRole f acc fa = stepPathMask @base @'[] @ms f (acc (liftCoyoneda fa))
  {-# INLINE stepRole #-}

instance forall base l ls ms m t3 acc acc' out' φ a rTail fa.
  ( fa ~ φ a
  , MapPath (l ': ls) (Coyoneda φ a -> rTail) rTail acc acc'
  , StepPathMask base (l ': ls) ms m t3 acc' out'
  ) => StepRole PCoY base (l ': ls) ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out' f
      (mapPath @(l ': ls) @(Coyoneda φ a -> rTail) @rTail (\g -> g (liftCoyoneda fa)) acc)
  {-# INLINE stepRole #-}

-- | Coyoneda lowering: unrolls 'Coyoneda' to underlying functor via single 'fmap'.
instance forall base active ms m t3 acc acc' out φ inner.
  ( Functor φ
  , MapPath (Init active) (Coyoneda φ inner) (φ inner) acc acc'
  , StepPathMask base active ms m t3 acc' out
  ) => StepRole PUnCoY base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @active @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(Coyoneda φ inner) @(φ inner) lowerCoyoneda acc)
  {-# INLINE stepRole #-}

-- | Yoneda lifting: wraps argument in 'Yoneda' for $O(1)$ composition.
instance (Functor φ, ExpectArrow "StepRole PYon" acc (Yoneda φ a) rTail, fa ~ φ a, StepPathMask base '[] ms m t3 rTail out')
  => StepRole PYon base '[] ms m t3 acc (fa -> out') where
  stepRole f acc fa = stepPathMask @base @'[] @ms f (acc (liftYoneda fa))
  {-# INLINE stepRole #-}

instance forall base l ls ms m t3 acc acc' out' φ a rTail fa.
  ( Functor φ, fa ~ φ a
  , MapPath (l ': ls) (Yoneda φ a -> rTail) rTail acc acc'
  , StepPathMask base (l ': ls) ms m t3 acc' out'
  ) => StepRole PYon base (l ': ls) ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out' f
      (mapPath @(l ': ls) @(Yoneda φ a -> rTail) @rTail (\g -> g (liftYoneda fa)) acc)
  {-# INLINE stepRole #-}

-- | Yoneda lowering: extracts underlying functor from 'Yoneda' (zero constraints).
instance forall base active ms m t3 acc acc' out φ inner.
  ( MapPath (Init active) (Yoneda φ inner) (φ inner) acc acc'
  , StepPathMask base active ms m t3 acc' out
  ) => StepRole PUnYon base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @active @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(Yoneda φ inner) @(φ inner) lowerYoneda acc)
  {-# INLINE stepRole #-}

-- | Codensity lifting: lifts monadic argument into 'Codensity' for CPS fusion.
instance (Monad m', ExpectArrow "StepRole PCodM" acc (Codensity m' a) rTail, ma ~ m' a, StepPathMask base '[] ms m t3 rTail out')
  => StepRole PCodM base '[] ms m t3 acc (ma -> out') where
  stepRole f acc ma = stepPathMask @base @'[] @ms f (acc (liftCodensity ma))
  {-# INLINE stepRole #-}

instance forall base l ls ms m t3 acc acc' out' m' a rTail ma.
  ( Monad m', ma ~ m' a
  , MapPath (l ': ls) (Codensity m' a -> rTail) rTail acc acc'
  , StepPathMask base (l ': ls) ms m t3 acc' out'
  ) => StepRole PCodM base (l ': ls) ms m t3 acc (ma -> out') where
  stepRole f acc ma =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out' f
      (mapPath @(l ': ls) @(Codensity m' a -> rTail) @rTail (\g -> g (liftCodensity ma)) acc)
  {-# INLINE stepRole #-}

-- | Codensity lowering: runs 'Codensity' back to underlying monad.
instance forall base active ms m t3 acc acc' out m' inner.
  ( Applicative m'
  , MapPath (Init active) (Codensity m' inner) (m' inner) acc acc'
  , StepPathMask base active ms m t3 acc' out
  ) => StepRole PUnCod base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @active @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(Codensity m' inner) @(m' inner) lowerCodensity acc)
  {-# INLINE stepRole #-}

-- | Density lifting: lifts comonadic argument into 'Density'.
instance (Comonad w, ExpectArrow "StepRole PDenW" acc (Density w a) rTail, wa ~ w a, StepPathMask base '[] ms m t3 rTail out')
  => StepRole PDenW base '[] ms m t3 acc (wa -> out') where
  stepRole f acc wa = stepPathMask @base @'[] @ms f (acc (liftDensity wa))
  {-# INLINE stepRole #-}

instance forall base l ls ms m t3 acc acc' out' w a rTail wa.
  ( Comonad w, wa ~ w a
  , MapPath (l ': ls) (Density w a -> rTail) rTail acc acc'
  , StepPathMask base (l ': ls) ms m t3 acc' out'
  ) => StepRole PDenW base (l ': ls) ms m t3 acc (wa -> out') where
  stepRole f acc wa =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out' f
      (mapPath @(l ': ls) @(Density w a -> rTail) @rTail (\g -> g (liftDensity wa)) acc)
  {-# INLINE stepRole #-}

-- | Density lowering: runs 'Density' back to underlying comonad.
instance forall base active ms m t3 acc acc' out w inner.
  ( Comonad w
  , MapPath (Init active) (Density w inner) (w inner) acc acc'
  , StepPathMask base active ms m t3 acc' out
  ) => StepRole PUnDen base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @active @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(Density w inner) @(w inner) lowerDensity acc)
  {-# INLINE stepRole #-}

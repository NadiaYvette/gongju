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

-- | Module: Gongju.Profunctor
-- Description: Profunctors and Indexed Profunctors for Gongju
--
-- Plugs canonical 'Profunctor' from 'Data.Profunctor' and 'IxProfunctor' from
-- 'Data.Profunctor.Indexed' into Gongju's open tape composition engine without modifying Core.
--
-- Supports:
-- * Contravariant input pre-processing via 'P1' / 'lmap'.
-- * Covariant output post-processing via 'P2' / 'rmap'.
-- * Simultaneous bidirectional mapping via 'dimap'.
module Gongju.Profunctor
  ( -- * Re-exported Canonical Profunctor Classes
    Profunctor(..)
  , dimap'
  , lmap'
  , rmap'
    -- * Re-exported Indexed Profunctors
  , IxProfunctor
  , ixcontramap
    -- * Open Profunctor Tags
  , P1
  , P2
    -- * Ergonomic Aliases
  , PP1
  , PP2
  ) where

import qualified Data.Profunctor as P
import Data.Profunctor
  ( Profunctor (..)
  )
import qualified Data.Profunctor.Indexed as IxP
import Gongju.Composition
  ( InOrder
  , MapPath (..)
  , MapStep (..)
  , PL
  )

-- | Profunctor first slot tag (contravariant).
data P1

-- | Profunctor second slot tag (covariant).
data P2

-- | In-order profunctor first-slot (contravariant) mapping alias.
type PP1 = InOrder (PL '[P1])

-- | In-order profunctor second-slot (covariant) mapping alias.
type PP2 = InOrder (PL '[P2])

-- | Type alias specializing 'Data.Profunctor.Indexed.Profunctor' as 'IxProfunctor'.
type IxProfunctor = IxP.Profunctor

-- | Re-export indexed profunctor index contramap.
ixcontramap :: IxProfunctor p => (j -> i) -> p i a b -> p j a b
ixcontramap = IxP.ixcontramap
{-# INLINE ixcontramap #-}

-- | Strict variant of 'dimap'.
dimap' :: Profunctor p => (a -> b) -> (c -> d) -> p b c -> p a d
dimap' = P.dimap
{-# INLINE dimap' #-}

-- | Strict variant of 'lmap'.
lmap' :: Profunctor p => (a -> b) -> p b c -> p a c
lmap' = P.lmap
{-# INLINE lmap' #-}

-- | Strict variant of 'rmap'.
rmap' :: Profunctor p => (b -> c) -> p a b -> p a c
rmap' = P.rmap
{-# INLINE rmap' #-}

-- ---------------------------------------------------------------------------
-- MapStep Instances for Profunctor Layers
-- ---------------------------------------------------------------------------

-- | Pre-compose argument 1 of a Profunctor contravariantly via 'lmap'.
instance (Profunctor p, s ~ p b c, t ~ p a c, MapPath ls a b a b)
  => MapStep P1 ls a b s t where
  mapStep f = P.lmap (mapPath @ls f)
  {-# INLINE mapStep #-}

-- | Post-compose argument 2 of a Profunctor covariantly via 'rmap'.
instance (Profunctor p, s ~ p a b, t ~ p a c, MapPath ls b c b c)
  => MapStep P2 ls b c s t where
  mapStep f = P.rmap (mapPath @ls f)
  {-# INLINE mapStep #-}

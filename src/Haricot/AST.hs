module Haricot.AST where

import qualified Data.List           as L
import           Data.Scientific     (Scientific)
import           Data.Text.Lazy      (Text, intercalate, unpack)
import           Data.Time.Calendar  (Day)
import           Data.Maybe(catMaybes)
import qualified Text.Megaparsec.Pos as P

data Directive
  = Bal Balance
  | Opn Open
  | Cls Close
  | Trn Transaction
  | Prc Price
  | Opt Option
  | Inc Include
  deriving (Eq, Show)

data Balance = Balance
  { _pos       :: Maybe P.SourcePos
  , _date      :: Day
  , _account   :: AccountName
  , _amount    :: Scientific
  , _commodity :: CommodityName
  } deriving (Eq, Show)

data Open = Open
  { _pos         :: Maybe P.SourcePos
  , _date        :: Day
  , _account     :: AccountName
  , _restriction :: Restriction
  } deriving (Show, Eq)

data Restriction
  = NoRestriction
  | RestrictedTo [CommodityName]
  deriving (Show, Eq)

instance Monoid Restriction where
  mempty = RestrictedTo []
  RestrictedTo x `mappend` RestrictedTo y = RestrictedTo (x `L.union` y)
  _ `mappend` _ = NoRestriction

compatibleWith :: CommodityName -> Restriction -> Bool
compatibleWith _ NoRestriction    = True
compatibleWith c (RestrictedTo r) = c `elem` r

data Close = Close
  { _pos     :: Maybe P.SourcePos
  , _date    :: Day
  , _account :: AccountName
  } deriving (Show, Eq)

data Price = Price
  { _pos             :: P.SourcePos
  , _date            :: Day
  , _commodity       :: CommodityName
  , _price           :: Scientific
  , _targetCommodity :: CommodityName
  } deriving (Show, Eq)

data Transaction = Transaction
  { _pos         :: Maybe P.SourcePos
  , _date        :: Day
  , _flag        :: Flag
  , _description :: Text
  , _tags        :: [Tag]
  , _postings    :: [Posting]
  } deriving (Eq, Show)

data Posting = Posting
  { _pos       :: Maybe P.SourcePos
  , _account   :: AccountName
  , _amount    :: Scientific
  , _commodity :: CommodityName
  , _lot       :: Lot
  } deriving (Show, Eq)

data Flag
  = Complete
  | Incomplete
  deriving (Eq, Show)

newtype Tag =
  Tag Text
  deriving (Show, Eq)

data Lot
  = Lot { _price           :: Scientific
        , _targetCommodity :: CommodityName
        , _date            :: Day
        , _label           :: Maybe Text }
  | NoLot
  deriving (Eq, Ord)

instance Show Lot where
  show NoLot = ""
  show (Lot p t d l) =
    L.intercalate ", " $ catMaybes [Just $ show p ++ " " ++ show t, Just $ show d, show <$> l]

data Include = Include
  {
    _pos      :: P.SourcePos,
    _filePath :: FilePath
  } deriving (Show, Eq)

data Option =
  Option P.SourcePos
         Text
         Text
  deriving (Show, Eq)

newtype AccountName = AccountName
  { _unAccountName :: [Text]
  } deriving (Eq, Ord)

instance Show AccountName where
  show = unpack . intercalate ":" . _unAccountName

newtype CommodityName = CommodityName
  { _unCommodityName :: Text
  } deriving (Eq, Ord)

instance Show CommodityName where
  show (CommodityName n) = unpack n

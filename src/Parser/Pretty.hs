{-# OPTIONS_GHC -fno-warn-orphans #-}

module Parser.Pretty where

import qualified Data.Map.Lazy as M
import Data.Text.Prettyprint.Doc
       (Pretty, (<+>), (<>), align, cat, dquotes, encloseSep, indent,
        line, nest, pretty, sep, vcat, vsep)
import Data.Time.Calendar (Day)

import Data.Account (Account(..), Accounts(..))
import Data.AccountName (AccountName(..))
import Data.Amount (Amount(..))
import Data.Commodity (CommodityName(..))
import Data.Holdings (Holdings(..))
import Data.Posting (Posting(..), PostingPrice(..))
import Data.Price (Price(..))
import Data.Transaction (Flag(..), Tag(..), Transaction(..))
import Parser.AST
       (Balance(..), Close(..), Directive(..), Include(..), Open(..),
        Option(..), PostingDirective(..), PriceDirective(..))

instance (Show a) => Pretty (Account a) where
  pretty (Account a h) = pretty h <+> line <+> nest 2 (pretty a)

instance (Show a) => Pretty (Accounts a) where
  pretty (Accounts m) = vsep (fmap f (M.toList m))
    where
      f (name, account) = pretty name <+> pretty account

instance Pretty AccountName where
  pretty = pretty . show

instance Show a => Pretty (Amount a) where
  pretty Amount {..} = pretty (show _amount) <+> pretty _commodity

instance Pretty CommodityName where
  pretty = pretty . _unCommodityName

instance Pretty Day where
  pretty = pretty . show

instance Show a => Pretty (Price a) where
  pretty Price {..} = pretty _amount

instance Pretty Transaction where
  pretty Transaction {..} =
    pretty _date <+>
    pretty _flag <+>
    dquotes (pretty _description) <+>
    cat (map pretty _tags) <> line <> (indent 2 . vcat) (map pretty _postings)

instance Pretty Flag where
  pretty Complete = "*"
  pretty Incomplete = "!"

instance Pretty Tag where
  pretty (Tag t) = pretty t

instance (Show a) => Pretty (Holdings a) where
  pretty (Holdings h) = align $ vsep (map f (M.toList h))
    where
      f (c, a) = (pretty . show) a <+> pretty c

instance (Show a) => Pretty (Posting a) where
  pretty Posting {..} =
    pretty _postingAccountName <+>
    pretty _amount <+> pretty _price <+> pretty' _lotCost _lotLabel _lotDate
    where
      pretty' Nothing Nothing Nothing = mempty
      pretty' c' l' d' =
        encloseSep "{" "}" "," [pretty c', pretty l', pretty d']

instance (Show a) => Pretty (PostingPrice a) where
  pretty (UnitPrice p) = "@" <+> pretty p
  pretty (TotalPrice a) = "@@" <+> pretty a

instance Pretty (Directive a) where
  pretty (Opn x _) = pretty x
  pretty (Cls x _) = pretty x
  pretty (Bal x _) = pretty x
  pretty (Trn x _) = pretty x
  pretty (Prc x _) = pretty x
  pretty (Opt x _) = pretty x
  pretty (Inc x _) = pretty x

instance Pretty Balance where
  pretty Balance {..} =
    pretty _date <+> "balance" <+> pretty _accountName <+> pretty _amount

instance Pretty Open where
  pretty Open {..} =
    pretty _date <+>
    "open" <+> pretty _accountName <+> sep (map pretty _commodities)

instance Pretty Close where
  pretty Close {..} = pretty _date <+> "close" <+> pretty _accountName

instance Pretty PriceDirective where
  pretty PriceDirective {..} = pretty _date <+> "price" <+> pretty _price

instance Pretty Include where
  pretty (Include filePath) = "include" <+> pretty filePath

instance Pretty Option where
  pretty (Option d t) = "option" <+> pretty d <+> pretty t

instance Pretty PostingDirective where
  pretty (CompletePosting p) = pretty p
  pretty (WildcardPosting n) = pretty n

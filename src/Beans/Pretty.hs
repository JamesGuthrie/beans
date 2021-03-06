{-# OPTIONS_GHC -fno-warn-orphans #-}

module Beans.Pretty
  ( prettyPrint
  , pretty
  , prettyPrintLedger
  )
where

import           Beans.Model                    ( Account(..)
                                                , Accounts
                                                , Amount
                                                , Date
                                                , Commodity(..)
                                                , Ledger
                                                , Lot(..)
                                                , Position(..)
                                                , Command(..)
                                                , Dated(..)
                                                , Directive(..)
                                                , Flag(..)
                                                , Include(..)
                                                , Option(..)
                                                , Tag(..)
                                                , Restriction(..)
                                                )
import qualified Beans.Data.Map                as M
import           Data.Monoid                    ( Sum(..) )
import           Data.Scientific                ( Scientific
                                                , formatScientific
                                                , FPFormat(Fixed)
                                                )
import           Data.Text.Prettyprint.Doc

instance Pretty Amount where
  pretty = pretty . formatScientific Fixed (Just 2) . getSum

instance Pretty Scientific where
  pretty = pretty . show

instance Pretty Account where
  pretty = pretty . show

instance Pretty Commodity where
  pretty (Commodity c) = pretty c

instance Pretty Date where
  pretty = pretty . show


prettyAccounts :: Accounts -> [Doc a]
prettyAccounts = concatMap p . M.toList
 where
  p (Position a _ l, v) = fmap g (M.toList v)
    where g (c, s) = pretty a <+> pretty s <+> pretty c <+> pretty l

instance Pretty Flag where
  pretty Complete   = "*"
  pretty Incomplete = "!"

instance Pretty Tag where
  pretty (Tag t) = pretty t

instance Pretty Lot where
  pretty Lot {lLabel, lPrice, lTargetCommodity, lDate} =
    encloseSep "{" "}" "," $
    [pretty lPrice, pretty lTargetCommodity, pretty lDate] ++
    case lLabel of
      Nothing -> []
      Just l  -> [pretty l]

instance Pretty Directive where
  pretty (DatedCommandDirective d) = pretty d
  pretty (OptionDirective o)       = pretty o
  pretty (IncludeDirective i)      = pretty i

instance Pretty a => Pretty (Dated a) where
  pretty (Dated day x) = pretty day <+> pretty x

instance Pretty Command where
  pretty Transaction {..} =
    pretty tFlag <+>
    dquotes (pretty tDescription) <+>
    cat (pretty <$> tTags) <> line <> (indent 2 . vcat) (prettyAccounts tPostings) <> hardline
  pretty Balance {bAccount, bAmount, bCommodity} =
    "balance" <+> pretty bAccount <+> pretty bAmount <+> pretty bCommodity
  pretty Open {oAccount, oRestriction} =
    "open" <+> pretty oAccount <+> pretty oRestriction
  pretty Close {cAccount} = "close" <+> pretty cAccount
  pretty Price {prCommodity, prPrice, prTargetCommodity} =
    "price" <+> pretty prCommodity <+> pretty prPrice <+> pretty prTargetCommodity

instance Pretty Restriction where
  pretty NoRestriction    = mempty
  pretty (RestrictedTo c) = hsep (map pretty c)


instance Pretty Include where
  pretty (Include _ filePath) = "include" <+> pretty filePath

instance Pretty Option where
  pretty (Option _ d t) = "option" <+> pretty d <+> pretty t

prettyPrint :: [Directive] -> IO ()
prettyPrint = print . vsep . map ((<> hardline) . pretty)

prettyPrintLedger :: Ledger -> IO ()
prettyPrintLedger = print . vsep . fmap ((<> hardline) . pretty)

module Beans.Import.CH.Postfinance
  ( parseEntries, name
  ) where

import           Beans.Data.Accounts        (Amount, Commodity (Commodity))
import           Beans.Import.Common        (Entry (..), ImporterException (..))
import           Control.Monad              (void)
import           Control.Monad.Catch        (MonadThrow, throwM)
import           Control.Monad.IO.Class     (MonadIO, liftIO)
import qualified Data.ByteString            as BS
import           Data.Monoid                (Sum (Sum))
import           Data.Text                  (Text)
import qualified Data.Text                  as T
import           Data.Text.Encoding         (decodeLatin1)
import           Data.Time.Calendar         (Day, fromGregorian)
import           Data.Void                  (Void)

import           Text.Megaparsec            (Parsec, count, manyTill, optional,
                                             parse, parseErrorPretty,
                                             skipManyTill, some, (<|>))
import           Text.Megaparsec.Char       (alphaNumChar, anyChar, char,
                                             digitChar, eol)
import qualified Text.Megaparsec.Char.Lexer as L


name :: Text
name = "ch.postfinance" :: Text

parseEntries :: (MonadIO m, MonadThrow m) => FilePath -> m [Entry]
parseEntries f = do
  source <- liftIO $ decodeLatin1 <$> BS.readFile f
  case parse postfinanceData mempty source of
    Left  e -> (throwM . ImporterException . parseErrorPretty) e
    Right d -> return d

type Parser = Parsec Void Text

postfinanceData :: Parser [Entry]
postfinanceData = do
  commodity <- count 3 ignoreLine >> ignoreField >> currency
  entries   <- ignoreLine >> some (entry commodity)
  _         <- eol >> ignoreLine >> ignoreLine
  return entries

entry :: Commodity -> Parser Entry
entry commodity =
  Entry
    <$> date
    <*> description
    <*> entryAmount
    <*> pure commodity
    <*> date
    <*> pure name
    <*> balance

entryAmount :: Parser Amount
entryAmount = field $ credit <|> debit
 where
  debit  = amount <* separator
  credit = separator *> amount

currency :: Parser Commodity
currency = field $ Commodity . T.pack <$> some alphaNumChar

date :: Parser Day
date = field $ fromGregorian <$> int 4 <*> (dash >> int 2) <*> (dash >> int 2)
 where
  dash = char '-'
  int n = read <$> count n digitChar

description :: Parser Text
description = quote >> T.pack <$> manyTill anyChar (quote >> separator)
  where quote = char '"'

amount :: Parser Amount
amount = Sum <$> L.signed mempty L.scientific

balance :: Parser (Maybe Amount)
balance = field $ optional amount

ignoreLine :: Parser ()
ignoreLine = void $ skipManyTill anyChar eol

ignoreField :: Parser ()
ignoreField = void $ skipManyTill anyChar separator

separator :: Parser ()
separator = void semicolon <|> void eol where semicolon = char ';'

field :: Parser a -> Parser a
field = L.lexeme separator

module Parser.Interpreter
  ( completePostings
  ) where

import Control.Monad.Catch (Exception, MonadThrow, throwM)
import Data.Account (AccountName)
import Data.Amount (Amount(..), (<@@>))
import Data.Decimal (Decimal)
import qualified Data.Holdings as H
import Data.Posting (Posting(..), PostingPrice(..))
import Data.Price ((<@>))
import Parser.AST (PostingDirective(..))

data HaricotException =
  UnbalancedTransaction
  deriving (Eq, Show)

instance Exception HaricotException

completePostings :: (MonadThrow m) => [PostingDirective] -> m [Posting Decimal]
completePostings p =
  case (calculateImbalances postings, wildcardAccount) of
    ([], []) -> return postings
    (im, [account]) -> return $ postings ++ (balance account <$> im)
    _ -> throwM UnbalancedTransaction
  where
    wildcardAccount = [n | WildcardPosting n <- p]
    postings = [p' | CompletePosting p' <- p]

balance :: (Num a) => AccountName -> Amount a -> Posting a
balance account amount =
  Posting account (negate <$> amount) Nothing Nothing Nothing Nothing

calculateImbalances :: (Ord a, Fractional a) => [Posting a] -> [Amount a]
calculateImbalances =
  H.toList . H.filter ((> 0.005) . abs) . H.fromList . fmap weight

weight :: Num a => Posting a -> Amount a
weight Posting {..} =
  case (_lotCost, _price) of
    (Just lotCost, _) -> _amount <@> lotCost
    (Nothing, Just (UnitPrice unitPrice)) -> _amount <@> unitPrice
    (Nothing, Just (TotalPrice totalPrice)) -> _amount <@@> totalPrice
    _ -> _amount

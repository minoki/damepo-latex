import Control.Applicative
import Numeric
import Control.Arrow
import Data.Char (ord,chr,toUpper)
import Data.List
import System.Environment (getArgs)

leftpadWith0 :: Int -> String -> String
leftpadWith0 n s | length s < n = leftpadWith0 n ('0':s)
                 | otherwise = s

showUnicodeEsc :: Int -> String
showUnicodeEsc c | chr c `elem` "-]\\" = ['\\', chr c]
                 | c < 0x80 = [chr c]
                -- | c < 0x10000 && not (0xD800 <= c && c <= 0xDFFF) = [chr c] -- "\\u" ++ leftpadWith0 4 (showHEX c "")
                 | c < 0x10000 = "\\\\u" ++ leftpadWith0 4 (showHEX c "")
                 | otherwise = "\\\\u{" ++ showHEX c "}"
  where showHEX = (map toUpper .) . showHex

showUnicodeEscRange :: Int -> Int -> String
showUnicodeEscRange x y | x == y = showUnicodeEsc x
                        | otherwise = showUnicodeEsc x ++ "-" ++ showUnicodeEsc y

buildRangeRx :: [(Int,Int)] -> String
buildRangeRx [] = ""
buildRangeRx [(x,y)] | x == y = showUnicodeEsc x
buildRangeRx xs = "[" ++ concatMap (uncurry showUnicodeEscRange) xs ++ "]"

setToRanges :: (Enum a, Eq a) => [a] -> [(a,a)]
setToRanges [] = []
setToRanges [c] = [(c,c)]
setToRanges (x:xs) = loop x x xs
  where loop x y [] = [(x,y)]
        loop x y (z:zs) | z == succ y = loop x z zs
                        | otherwise = (x,y) : loop z z zs

parseUnicodeDataLine :: String -> Maybe (Int,String,String)
parseUnicodeDataLine s
  | (codepoint_s,';':xs) <- span (/= ';') s
  , (description,';':ys) <- span (/= ';') xs
  , (cat,';':_) <- span (/= ';') ys
  , [(codepoint,"")] <- readHex codepoint_s = Just (codepoint,description,cat)
  | otherwise = Nothing

parseUnicodeData :: [String] -> [(Int,String)]
parseUnicodeData [] = []
parseUnicodeData (x:xs) | Just (xp,xd,xc) <- parseUnicodeDataLine x
                        , isSuffixOf ", First>" xd
                        , y:ys <- xs
                        , Just (yp,yd,yc) <- parseUnicodeDataLine y
                        , isSuffixOf ", Last>" yd
                        = if xc /= yc
                          then error "General Category mismatch"
                          else [(cp,xc) | cp <- [xp..yp]]++parseUnicodeData ys
                        | Just (xp,xd,xc) <- parseUnicodeDataLine x
                        = (xp,xc):parseUnicodeData xs
                        | otherwise = error "failed to parse"

encodeUtf16 :: Int -> Either Int (Int,Int)
encodeUtf16 x | x < 0x10000 = Left x
              | otherwise = let xm = x - 0x10000
                                (hi',lo') = xm `divMod` 0x400
                            in Right (0xD800 + hi', 0xDC00 + lo')

partitionEither :: [Either a b] -> ([a],[b])
--partitionEither [] = ([],[])
--partitionEither (Left x:xs) = first (x:) $ partitionEither xs
--partitionEither (Right y:xs) = second (y:) $ partitionEither xs
partitionEither = foldr (either (first . (:)) (second . (:))) ([],[])

eqFst :: Eq a => (a,b) -> (a,b) -> Bool
eqFst x y = fst x == fst y

eqSnd :: Eq b => (a,b) -> (a,b) -> Bool
eqSnd x y = snd x == snd y

-- groupByFst [(1,2),(1,3),(1,5),(2,3),(3,1),(3,7)]
-- ->[(1,[2,3,5]),(2,[3]),(3,[1,7])]
groupByFst :: Eq a => [(a,b)] -> [(a,[b])]
groupByFst [] = []
groupByFst ((s,t):xs) | (s',t'):_ <- xs
                      , s == s' = let (u,v):ys = groupByFst xs
                                  in (u,t:v):ys
                      | otherwise = (s,[t]):groupByFst xs

groupBySnd :: Eq b => [(a,b)] -> [([a],b)]
groupBySnd = map swap . groupByFst . map swap
  where swap (x,y) = (y,x)

isLetter = (== 'L') . head

compareByFst :: (Ord a, Ord b) => (a,b) -> (a,b) -> Ordering
compareByFst (x,y) (x',y') = case compare x x' of
  EQ -> compare y y'
  c -> c

compareBySnd :: (Ord a, Ord b) => (a,b) -> (a,b) -> Ordering
compareBySnd (x,y) (x',y') = case compare y y' of
  EQ -> compare x x'
  c -> c

main = do args <- getArgs
          let catPrefix | (x:_) <- args = x
                        | otherwise = "L" -- Letter
          l <- lines <$> readFile "UnicodeData.txt"
          let codepoints = parseUnicodeData l
              letters = map fst $ filter (isPrefixOf catPrefix . snd) codepoints
              (bmp,surrogates) = partitionEither $ map encodeUtf16 letters
              bmprx = buildRangeRx $ setToRanges bmp
          --putStrLn (buildRangeRx $ setToRanges letters)
          --putStr (buildRangeRx $ setToRanges bmp)
          let surrogateGroups :: [(Int,[(Int,Int)])]
              surrogateGroups = map (second setToRanges) $ groupByFst surrogates
              surrogateGroups2 :: [([(Int,Int)],[(Int,Int)])]
              surrogateGroups2 = sortBy compareByFst $ map (first setToRanges) $ groupBySnd $ sortBy compareBySnd surrogateGroups
              surrogatesRx :: [String]
              surrogatesRx = map (uncurry (++) . (buildRangeRx *** buildRangeRx)) surrogateGroups2
          putStrLn (concat $ intersperse "|" $ bmprx:surrogatesRx)
